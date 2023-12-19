package main

import "fmt"

func main() {
	prefix := `
  - delegate:
      name: nginx1-80
      namespace: default
    match:
    - uri:
        prefix: /`

	// 定义所有小写字母
	letters := "abcdefghijklmnopqrstuvwxyz"

	// 生成所有可能性
	for i := 0; i < len(letters); i++ {
		for j := 0; j < len(letters); j++ {
			for k := 0; k < 10; k++ {
				// 生成字符串
				possibility := string(letters[i]) + string(letters[j]) + string(letters[k])
				fmt.Printf("%s", prefix+possibility)
			}
		}
	}
}
