package main

import (
	"C"
	"encoding/hex"
	"fmt"
	"log"
	"os"

	"github.com/consensys/gnark/frontend"
	"github.com/eon-protocol/eonark"
	"github.com/eon-protocol/eonark/accounts/permissionless"
)
import (
	"bytes"
	"unsafe"

	"github.com/consensys/gnark-crypto/ecc/bls12-377/fr"
	bls12381 "github.com/consensys/gnark-crypto/ecc/bls12-381"
)

type Account struct {
	X frontend.Variable `gnark:",public"`
	Y frontend.Variable `gnark:",public"`
	Z frontend.Variable `gnark:",public"`
	W frontend.Variable `gnark:",public"`
}

func (me *Account) Define(api frontend.API) error {
	_, err := api.(frontend.Committer).Commit(me.X)
	return err
}

//export prove
func prove(X, Y, Z, W unsafe.Pointer) unsafe.Pointer {
	BX := C.GoBytes(X, 32)
	BY := C.GoBytes(Y, 32)
	BZ := C.GoBytes(Z, 32)
	BW := C.GoBytes(W, 32)
	var pk eonark.Pk
	if err := pk.Compile(&permissionless.Account{}); err != nil {
		return nil
	}
	var x, y, z, w fr.Element
	if err := bls12381.NewDecoder(bytes.NewReader(BX)).Decode(&x); err != nil {
		return nil
	}
	if err := bls12381.NewDecoder(bytes.NewReader(BY)).Decode(&y); err != nil {
		return nil
	}
	if err := bls12381.NewDecoder(bytes.NewReader(BZ)).Decode(&z); err != nil {
		return nil
	}
	if err := bls12381.NewDecoder(bytes.NewReader(BW)).Decode(&w); err != nil {
		return nil
	}
	_, _, proof, err := pk.Prove(&permissionless.Account{X: x, Y: y, Z: z, W: w})
	if err != nil {
		return nil
	}
	buf := bytes.NewBuffer(nil)
	if _, err := proof.WriteTo(buf); err != nil {
		return nil
	}
	return C.CBytes(buf.Bytes())
}

func main() {
	fmt.Println("Pk:")
	var pk eonark.Pk
	if err := pk.Compile(&permissionless.Account{}); err != nil {
		log.Fatalln(err)
	}
	{
		enc := hex.NewEncoder(os.Stdout)
		if _, err := pk.WriteTo(enc); err != nil {
			log.Fatalln(err)
		}
		fmt.Println()
	}
	fmt.Println("Vk:")
	vk := pk.Vk()
	{
		enc := hex.NewEncoder(os.Stdout)
		if _, err := vk.WriteTo(enc); err != nil {
			log.Fatalln(err)
		}
		fmt.Println()
	}

	fmt.Println("Addr:")
	addr := vk.Address()
	fmt.Println(addr.Text(16))
}
