package main

import (
	"os"
    "fmt"
    "net/http"
	"io"
	"time"
	"strings"
	"regexp"
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
		case msg := <- msg_chan:
			notice_msgs = append(notice_msgs, msg)
			
		case <- ticker.C:
			countTick += 1			
			timeNow = time.Now().Unix()

			if countTick % (3600*24) == 0 || timeNow % (3600*24) == 0 {
				// a new day
				countNoticePerDay = 0
				countTick = 0
			}

			timeGoing := (int)(timeNow - lastNotice)
			if timeGoing < 35 {
				// 30s 内不能重复发送
				continue;
			}

			if countRetry > 0 {
				if timeGoing < (180 + countRetry * 200) {
					// 每失败重复1次，增加 3 + 3 * N 分钟
					continue;
				}

				if countRetry >= 6 {
					countRetry = 1
				}
			}

			if len(notice_msgs) >= 1 {
				// notice not empty

				if len(notice_msgs) >= 5 || countNoticePerDay < 10 || timeNow - lastNotice >= 6 * 60 {
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

func main() {
	re_kernel_lts := regexp.MustCompile(`<tr><td>([0-9.]+)</td>`)
	re_xanmod_lts := regexp.MustCompile(`/releases/lts/([0-9]+\.[0-9]+)`)
	re_xanmod_main := regexp.MustCompile(`/releases/main/([0-9]+\.[0-9]+)`)
	re_xanmod_edge := regexp.MustCompile(`/releases/edge/([0-9]+\.[0-9]+)`)

	fmt.Printf("%s %q\n", date_now_string(), re_kernel_lts.FindStringSubmatch("<tr><td>6.6</td><tr><td>6.1</td>"))
	fmt.Printf("%s %q\n", date_now_string(), re_xanmod_lts.FindStringSubmatch("master.dl.sourceforge.net/project/xanmod/releases/lts/6.6.63-xanmod1"))
	fmt.Printf("%s %q\n", date_now_string(), re_xanmod_main.FindStringSubmatch(" ]&nbsp;&nbsp;&nbsp;&nbsp;[ <a href=\"https://master.dl.sourceforge.net/project/xanmod/releases/main/6.11.11-xanmod1"))

	notice_chan := make(chan NoticeMsg, 64)
	notice_token := os.Getenv("MIAO_URL")
	if len(notice_token) > 5 {
		go worker_notice(notice_token, notice_chan)
	}

	http.HandleFunc("/notice", func(w http.ResponseWriter, r *http.Request) {
        queryParams := r.URL.Query()
        notice_type := queryParams.Get("t")
        notice_msg := queryParams.Get("msg")

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
					if version == "main"{
						re_xanmod = re_xanmod_main
					} else if version == "edge"{
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

			w.WriteHeader(res.StatusCode)
			io.Copy(w, res.Body)
		}
	})

    http.ListenAndServe(":2083", nil)

	// go build -o /dev/shm/xanmod  -ldflags "-s -w" xanmod.go && upx /dev/shm/xanmod && ./xanmod
}