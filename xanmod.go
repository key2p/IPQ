package main

import (
    "fmt"
    "net/http"
	"io"
	"regexp"
)

func main() {
	re_kernel_lts := regexp.MustCompile(`<tr><td>([0-9.]+)</td>`)
	re_xanmod_lts := regexp.MustCompile(`/releases/lts/([0-9]+\.[0-9]+)`)

	fmt.Printf("%q\n", re_kernel_lts.FindStringSubmatch("<tr><td>6.6</td><tr><td>6.1</td>"))
	fmt.Printf("%q\n", re_xanmod_lts.FindStringSubmatch("master.dl.sourceforge.net/project/xanmod/releases/lts/6.6.63-xanmod1"))

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        // Get query parameters as a map
        queryParams := r.URL.Query()
        version := queryParams.Get("version")

		requestURL := ""
		if version == "lts" {
			lts_version := ""

			requestURL = "https://www.kernel.org/category/releases.html"		
			res, err := http.Get(requestURL)
			if err == nil {
				defer res.Body.Close()
				data, err := io.ReadAll(res.Body)
				if err == nil {
					data_str := string(data)
					matchs := re_kernel_lts.FindStringSubmatch(data_str)
					if len(matchs) == 2 {
						lts_version = matchs[1]
					}				
				}
			} else {
				requestURL = "https://xanmod.org/"
				res, err = http.Get(requestURL)
				if err == nil {
					defer res.Body.Close()

					data, err := io.ReadAll(res.Body)
					if err == nil {
						data_str := string(data)
						matchs := re_xanmod_lts.FindStringSubmatch(data_str)
						if len(matchs) == 2 {
							lts_version = matchs[1]
						}				
					}
				}
			}

			if len(lts_version) > 0 {
				w.WriteHeader(200)
				_, _ = w.Write([]byte(fmt.Sprintf("<a href=\"%s/\">%s/</a>", lts_version, lts_version)))						
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
}