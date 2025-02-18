package main

import (
	"fmt"
	"io"
	"maps"
	"net/http"
	"os"
	"regexp"
	"slices"
	"strings"
	"time"
)

type NoticeMsg struct {
	Type string
	Msg  string
}

func date_now_string() string {
	return time.Now().Format("2006-01-02 15:04:05")
}

func worker_notice(notice_url string, msg_chan chan NoticeMsg) {
	var notice_msgs []NoticeMsg

	countRetry := 0
	countNoticePerDay := 0
	countTick := 0
	lastNotice := time.Now().Unix()
	timeNow := lastNotice

	ticker := time.NewTicker(1000 * time.Millisecond)

	for {
		select {
		case msg := <-msg_chan:
			notice_msgs = append(notice_msgs, msg)

		case <-ticker.C:
			countTick += 1
			timeNow = time.Now().Unix()

			if countTick%(3600*24) == 0 || timeNow%(3600*24) == 0 {
				// a new day
				countNoticePerDay = 0
				countTick = 0
			}

			timeGoing := (int)(timeNow - lastNotice)
			if timeGoing < 35 {
				// 30s 内不能重复发送
				continue
			}

			if countRetry > 0 {
				if timeGoing < (180 + countRetry*200) {
					// 每失败重复1次，增加 3 + 3 * N 分钟
					continue
				}

				if countRetry >= 6 {
					countRetry = 1
				}
			}

			if len(notice_msgs) >= 1 {
				// notice not empty

				if len(notice_msgs) >= 5 || countNoticePerDay < 10 || timeNow-lastNotice >= 6*60 {
					// 5 notice pending, or first 10 notice per day or 6 minutes passed
					lastNotice = timeNow
					countNoticePerDay += 1

					msg_count := 0
					msg_str := ""

					for _, msg := range notice_msgs {
						msg_type := msg.Type
						msg_msg := msg.Msg

						if len(msg_type) > 12 {
							msg_type = msg_type[0:12]
						}
						if len(msg_msg) > 12 {
							msg_msg = msg_msg[0:12]
						}

						msg_str += fmt.Sprintf("%s_%s+%%0a", msg_type, msg_msg)
						msg_count += 1

						if msg_count >= 8 {
							break
						}
					}

					requestURL := fmt.Sprintf("%s&text=%s", notice_url, msg_str)
					res, err := http.Get(requestURL)
					if err == nil {
						defer res.Body.Close()

						data, err := io.ReadAll(res.Body)
						if err == nil {
							data_str := string(data)
							if strings.Index(data_str, "完成") >= 0 || strings.Index(data_str, "成功") >= 0 {
								// success, clean
								countRetry = 0
								notice_msgs = notice_msgs[msg_count:]
							} else {
								// failed
								countRetry += 1
								fmt.Printf("%s http get %s error: %s\n", date_now_string(), requestURL, data_str)
							}
						}
					} else {
						fmt.Printf("%s http get %s error: %s\n", date_now_string(), requestURL, err.Error())
					}
				}
			}
		}
	}
}

type M3UChannel struct {
	Head string
	Urls []string
}
type M3UInfo struct {
	ipv6_first bool
	Head       string
	Body       map[string]*M3UChannel
}

func NewM3uInfo(ipv6_first bool) *M3UInfo {
	return &M3UInfo{
		ipv6_first: ipv6_first,
		Head:       "",
		Body:       make(map[string]*M3UChannel),
	}
}

func (m *M3UInfo) process_txt_file(data string) {
	channel_name := ""
	channel_info := &M3UChannel{}

	lines := strings.Split(data, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if len(line) < 5 {
			continue
		}

		if strings.Contains(line, "#genre") {
			continue
		}

		infos := strings.Split(line, ",")
		if len(infos) >= 2 && len(infos[0]) > 1 {
			channel_name = infos[0]
			url := strings.TrimSpace(infos[1])

			if len(url) > 0 && strings.Contains(url, "http") {
				exist_channel_info, exist := m.Body[channel_name]
				if exist {
					channel_info = exist_channel_info
					channel_info.Urls = append(channel_info.Urls, url)
				} else {
					head := fmt.Sprintf(`#EXTINF:-1 tvg-id="%s" tvg-name="%s" group-title="备用频道",%s`, channel_name, channel_name, channel_name)

					channel_info = &M3UChannel{Head: head, Urls: []string{url}}
					m.Body[channel_name] = channel_info
				}
			}
		}
	}
}

func (m *M3UInfo) process_m3u_file(data string) {
	re_tvg_name := regexp.MustCompile(`tvg-name="([^"]+)"`)
	channel_name := ""
	channel_info := &M3UChannel{}

	lines := strings.Split(data, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if len(line) == 0 {
			continue
		}

		if strings.HasPrefix(line, "#EXTM3U") {
			m.Head = line
		} else if strings.HasPrefix(line, "#EXTINF") {
			new_channel_name := ""
			new_tag_name := re_tvg_name.FindStringSubmatch(line)
			if len(new_tag_name) == 2 {
				new_channel_name = new_tag_name[1]
			} else {
				channel_infos := strings.Split(line, ",")
				if len(channel_infos) >= 2 {
					new_channel_name = channel_infos[len(channel_infos)-1]
				}
			}

			if len(channel_name) > 0 && len(channel_info.Urls) > 0 {
				m.Body[channel_name] = channel_info
			}

			if len(new_channel_name) > 0 {
				channel_name = new_channel_name
				exist_channel_info, exist := m.Body[channel_name]
				if exist {
					channel_info = exist_channel_info
				} else {
					channel_info = &M3UChannel{Head: line, Urls: nil}
				}
			}

		} else if strings.HasPrefix(line, "http") {
			channel_info.Urls = append(channel_info.Urls, line)
		}
	}

	if len(channel_name) > 0 && len(channel_info.Urls) > 0 {
		m.Body[channel_name] = channel_info
	}
}

func (m *M3UInfo) to_m3u() string {
	if len(m.Head) < 4 {
		m.Head = `#EXTM3U x-tvg-url="https://ghgo.xyz/https://raw.githubusercontent.com/Meroser/EPG-test/main/tvxml-test.xml.gz" catchup="append" catchup-source="?playseek=${(b)yyyyMMddHHmmss}-${(e)yyyyMMddHHmmss}"`
	}
	data := m.Head + "\n"

	channels := slices.Collect(maps.Keys(m.Body))
	slices.SortStableFunc(channels, func(url_i string, url_j string) int {
		return strings.Compare(url_i, url_j)
	})

	// fmt.Print("sort channels\n", channels)

	for _, channel := range channels {
		channel_info := m.Body[channel]
		data += channel_info.Head + "\n"

		channel_info.Urls = slices.Compact(channel_info.Urls)
		slices.SortStableFunc(channel_info.Urls, func(url_i string, url_j string) int {
			if m.ipv6_first && strings.Contains(url_i, "://[]") {
				return -1
			} else if m.ipv6_first && strings.Contains(url_j, "://[]") {
				return 1
			} else if strings.Contains(url_i, "sc.") {
				return -1
			}

			return strings.Compare(url_i, url_j)
		})

		for _, url := range channel_info.Urls {
			data += url + "\n"
		}
	}

	return data
}

func process_iptv(w http.ResponseWriter, r *http.Request) {
	//queryParams := r.URL.Query()
	//ipv6 := queryParams.Get("ipv6")
	//ipv6_first := (ipv6 == "1" || ipv6 == "true")

	requestURL := "https://gist.githubusercontent.com/inkss/0cf33e9f52fbb1f91bc5eb0144e504cf/raw/ipv6.m3u"
	res, err := http.Get(requestURL)
	if err == nil {
		defer res.Body.Close()

		w.WriteHeader(200)

		data, err := io.ReadAll(res.Body)
		if err == nil {
			_, _ = w.Write(data)

			// m3uifo := NewM3uInfo(ipv6_first)
			// m3uifo.process_m3u_file(string(data))

			// data_sccu, err := os.ReadFile("sctv.m3u")
			// if err == nil {
			// 	m3uifo.process_m3u_file(string(data_sccu))
			// }

			// data_sccu, err = os.ReadFile("sctv.txt")
			// if err == nil {
			// 	m3uifo.process_txt_file(string(data_sccu))
			// }

			// out_m3u := m3uifo.to_m3u()
			// if len(out_m3u) > 0 {
			// 	w.WriteHeader(200)
			// 	_, _ = w.Write([]byte(out_m3u))
			// 	return
			// }
		}

		data_sccu, err := os.ReadFile("sctv.m3u")
		if err == nil {
			_, _ = w.Write(data_sccu)
		}

		return
	}

	data_sccu, err := os.ReadFile("sctv.m3u")
	if err != nil {
		w.WriteHeader(502)
		_, _ = w.Write([]byte(fmt.Sprintf("{\"error\":\"%s\"}", err.Error())))
	} else {
		w.WriteHeader(200)
		_, _ = w.Write(data_sccu)
	}
}

func test_m3u() {
	m3uifo := NewM3uInfo(true)

	data_sccu, err := os.ReadFile("sctv.m3u")
	if err == nil {
		m3uifo.process_m3u_file(string(data_sccu))
	}

	data_sccu, err = os.ReadFile("sctv.txt")
	if err == nil {
		m3uifo.process_txt_file(string(data_sccu))
	}

	out_m3u := m3uifo.to_m3u()
	os.WriteFile("out.m3u", []byte(out_m3u), 0644)
}

func test() {
	test_m3u()
}

func main() {
	// test()

	re_kernel_lts := regexp.MustCompile(`<tr><td>([0-9.]+)</td>`)
	re_xanmod_lts := regexp.MustCompile(`/releases/lts/([0-9]+\.[0-9]+)`)
	re_xanmod_main := regexp.MustCompile(`/releases/main/([0-9]+\.[0-9]+)`)
	re_xanmod_edge := regexp.MustCompile(`/releases/edge/([0-9]+\.[0-9]+)`)
	re_xanmod_ver := regexp.MustCompile(`ChangeLog-([0-9.]+)-xanmod[0-9]+`)

	fmt.Printf("%s %q\n", date_now_string(), re_kernel_lts.FindStringSubmatch("<tr><td>6.6</td><tr><td>6.1</td>"))
	fmt.Printf("%s %q\n", date_now_string(), re_xanmod_lts.FindStringSubmatch("master.dl.sourceforge.net/project/xanmod/releases/lts/6.6.63-xanmod1"))
	fmt.Printf("%s %q\n", date_now_string(), re_xanmod_main.FindStringSubmatch(" ]&nbsp;&nbsp;&nbsp;&nbsp;[ <a href=\"https://master.dl.sourceforge.net/project/xanmod/releases/main/6.11.11-xanmod1"))

	notice_chan := make(chan NoticeMsg, 64)
	notice_token := os.Getenv("MIAO_URL")
	if len(notice_token) > 5 {
		go worker_notice(notice_token, notice_chan)
	}

	http.HandleFunc("/iptv.m3u", process_iptv)

	http.HandleFunc("/notice", func(w http.ResponseWriter, r *http.Request) {
		queryParams := r.URL.Query()
		notice_type := queryParams.Get("t")
		notice_msg := queryParams.Get("msg")
		notice_class := queryParams.Get("c")

		if notice_class == "fail" {
			// 失败不重要，不通知，记录即可。
			fmt.Printf("%s %s %s\n", date_now_string(), notice_msg, notice_type)
			w.WriteHeader(200)
			_, _ = w.Write([]byte(notice_msg))

			return
		}
		if notice_class == "ok" {
			build_log := fmt.Sprintf("%s %s %s\n", date_now_string(), notice_msg, notice_type)
			f, err := os.OpenFile("log.txt", os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0666)
			if err == nil {
				_, err = f.Write([]byte(build_log))
				f.Close()
			}
		}

		if len(notice_token) > 5 {
			notice_chan <- NoticeMsg{Type: notice_type, Msg: notice_msg}
		}

		w.WriteHeader(200)
		_, _ = w.Write([]byte(notice_msg))
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Get query parameters as a map
		queryParams := r.URL.Query()
		version := queryParams.Get("version")
		q_type := queryParams.Get("type")

		requestURL := ""
		if version == "lts" || version == "main" || version == "edge" {
			krl_version := ""

			// requestURL = "https://www.kernel.org/category/releases.html"
			// res, err := http.Get(requestURL)
			// if err == nil {
			// 	defer res.Body.Close()
			// 	data, err := io.ReadAll(res.Body)
			// 	if err == nil {
			// 		data_str := string(data)
			// 		matchs := re_kernel_lts.FindStringSubmatch(data_str)
			// 		if len(matchs) == 2 {
			// 			krl_version = matchs[1]
			// 		}
			// 	}
			// } else {

			requestURL := "https://xanmod.org/"
			res, err := http.Get(requestURL)
			if err == nil {
				defer res.Body.Close()

				data, err := io.ReadAll(res.Body)
				if err == nil {
					data_str := string(data)

					re_xanmod := re_xanmod_lts
					if version == "main" {
						re_xanmod = re_xanmod_main
					} else if version == "edge" {
						re_xanmod = re_xanmod_edge
					}

					matchs := re_xanmod.FindStringSubmatch(data_str)
					if len(matchs) == 2 {
						krl_version = matchs[1]
					}
				}
			}

			if len(krl_version) > 0 {
				w.WriteHeader(200)
				_, _ = w.Write([]byte(fmt.Sprintf("<a href=\"%s/\">%s/</a>", krl_version, krl_version)))
				return
			}

			version = "all"
		}

		if len(version) == 0 || version == "all" {
			requestURL = fmt.Sprintf("https://dl.xanmod.org/changelog/?C=M;O=D")
		} else {
			requestURL = fmt.Sprintf("https://dl.xanmod.org/changelog/%s/?C=M;O=D", version)
		}

		res, err := http.Get(requestURL)
		if err != nil {
			w.WriteHeader(502)
			_, _ = w.Write([]byte(fmt.Sprintf("{\"error\":\"%s\"}", err.Error())))
		} else {
			defer res.Body.Close()

			data, err := io.ReadAll(res.Body)
			if err == nil {
				data_str := string(data)
				matchs := re_xanmod_ver.FindStringSubmatch(data_str)
				if len(matchs) == 2 {
					version := fmt.Sprintf("%s%s", q_type, matchs[1])
					build_log, _ := os.ReadFile("log.txt")
					build_log_str := string(build_log)

					if strings.Index(build_log_str, version) >= 0 {
						w.WriteHeader(res.StatusCode)
						w.Write([]byte(version))
						return
					}
				}
			}

			w.WriteHeader(res.StatusCode)
			w.Write(data)
		}
	})

	http.ListenAndServe(":2083", nil)

	// go build -o /dev/shm/xanmod  -ldflags "-s -w" xanmod.go && upx /dev/shm/xanmod && ./xanmod
}
