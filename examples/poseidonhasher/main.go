package main

import (
	"fmt"
	"log"
	"runtime"
	"time"

	// curves and fields

	// gnark
	"github.com/consensys/gnark/frontend"
	"github.com/consensys/gnark/std/hash/poseidon2"

	"github.com/eon-protocol/eonark"
)

//
// -------------------- Inner circuit layer --------------------
//

type innerCircuit struct {
	X frontend.Variable `gnark:",public"`
	Y frontend.Variable `gnark:",public"`
	Z frontend.Variable `gnark:",public"`
	W frontend.Variable `gnark:",public"`
}

func (me *innerCircuit) Define(api frontend.API) error {
	v := api.Mul(me.X, me.X)
	api.AssertIsEqual(v, 1)
	_, err := api.(frontend.Committer).Commit(me.X)
	if err != nil {
		return err
	}

	hasher, err := poseidon2.NewMerkleDamgardHasher(api)
	if err != nil {
		return err
	}

	currentHash := me.X
	for i := 0; i < 100000; i++ {
		hasher.Reset()
		hasher.Write(currentHash)
		currentHash = hasher.Sum()

		if i%10000 == 0 {
			api.Println(fmt.Sprintf("Hash iteration %d", i))
		}
	}
	api.Println("Final hash result:", currentHash)
	api.AssertIsEqual(currentHash, "0")

	return nil
}

func main() {
	// 1. 查看 CPU 核心数
	fmt.Printf("CPU 核心数: %d\n", runtime.NumCPU())

	// 2. 查看当前使用的最大处理器数（GOMAXPROCS）
	fmt.Printf("当前使用的 GOMAXPROCS: %d\n", runtime.GOMAXPROCS(0))

	// 1) Compile the inner circuit: compile + prove (using SRS in share folder)
	var pk eonark.Pk
	start_time := time.Now()
	err := pk.Compile(&innerCircuit{})
	if err != nil {
		log.Fatalf("compile inner: %v", err)
	}
	elapsed := time.Since(start_time)
	fmt.Printf("compile inner 耗时: %.6f ms\n", float64(elapsed.Nanoseconds())/1e6)

	// inner circuit assignment: X=1 (satisfies X*X=1)
	innerAssign := &innerCircuit{X: 1, Y: 1, Z: 1, W: 1}

	// prove: return publics / proof
	start_time = time.Now()
	publicsMine, _, proofMine, err := pk.Prove(innerAssign)
	if err != nil {
		log.Fatalf("prove inner: %v", err)
	}
	elapsed = time.Since(start_time)
	fmt.Printf("prove inner 耗时: %.6f ms\n", float64(elapsed.Nanoseconds())/1e6)

	// sanity: run verification using verify functions in zk package
	vkMine := pk.Vk()
	start_time = time.Now()
	if err := vkMine.Verify(proofMine, publicsMine); err != nil {
		log.Fatalf("verify inner: %v", err)
	}
	elapsed = time.Since(start_time)
	fmt.Printf("verify inner 耗时: %.6f ms\n", float64(elapsed.Nanoseconds())/1e6)
}
