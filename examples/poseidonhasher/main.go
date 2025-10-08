package main

import (
	"fmt"
	"log"
	"runtime"
	"time"

	"github.com/consensys/gnark/frontend"

	"github.com/eon-protocol/eonark"
	"github.com/eon-protocol/eonark/circuits/hasher"
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

	h, err := hasher.NewPoseidon2FromParameters(api)
	if err != nil {
		return err
	}

	// 链式 hash
	currentHash := me.X
	const iterations = 10000
	api.Println(fmt.Sprintf("Starting %d iterations of Poseidon2 chain hashing", iterations))

	for i := 0; i < iterations; i++ {
		currentHash = h.HashCompressVars(currentHash, 0)
		if (i+1)%10000 == 0 {
			api.Println(fmt.Sprintf("Completed %d iterations", i+1))
		}
	}

	api.Println("Final hash result after 100,000 iterations:", currentHash)
	expectedFinalHash := "1234567890123456789012345678901234567890123456789012345678901234567890"
	api.AssertIsEqual(currentHash, expectedFinalHash)

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
