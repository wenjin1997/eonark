package main

import "C"
import "fmt"

//export Oops
func Oops() {
	fmt.Println("oops")
}

func main() {}
