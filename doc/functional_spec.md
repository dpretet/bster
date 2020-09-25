# Functional Specification


## Summary

- [Introduction](#Introduction)
- [Design Consideration](#Design-Consideration)
- [Commands](#Commands)
- [Memory Structure](#Memory-Structure)
- [Command Algorithms](#Command-Algorithms)


## Introduction

- [Binary tree](https://en.wikipedia.org/wiki/Binary_tree) and its advantages.
- [Usage example](https://stackoverflow.com/questions/2130416/what-are-the-applications-of-binary-trees).
    - Hash tree
    - Huffman coding
    - Radix tree
    - Merkle tree
    - Prefix tree


## Design Consideration

- RTL description in SystemVerilog
- [AMBA4](https://developer.arm.com/architectures/system-architectures/amba/documentation) compliant.
- [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) agnostic.
- Support any memory type, depth and size being AXI4 compliant. User can plug
  its own model if necessary.
- The IP provides 4 different interfaces:
    - 1 AXI4-lite interface to access the [register map](#Register-Map).
    - 1 AXI4-Stream slave to request [operations](#Commands) on the tree.
    - 1 AXI4-Stream master to get back command's completion.
    - 1 AXI4-Stream master to get back command's status.
- A node in the tree uses the `token` terminology to name an element to store.
  A token is considered as an abstract value and can represent anything:
    - It's interpreted as an **address** to locate a node.
    - Can mean address, data, id, ... the meaning depends of the
      application.
    - All operations parsing the tree rely on this field.


## Commands

All commands requests by the user are issued on AXI4S slave interface of the
IP. All commands' completion and status are driven on AXI4S master interfaces
of the IP.

TODO: Add description of AXI4S interface formatting for each command.


### Search

- Search token
    - Opcode = 0x10
    - Search across the tree by value.
    - Return the node information is successful, or 1 if not.

- Search smallest token
    - Opcode = 0x11
    - Parse the tree to find the smallest token's value.
    - Return the smallest value.

- Search biggest token
    - Opcode = 0x12
    - Parse the tree to find the biggest token's value.
    - Return the biggest value.

- (Search over node's data) (TBD)


### Insert

- Insert token
    - Opcode = 0x20
    - Insert a new token, optionally a data associated
    - Return 0 if operation was successfull, 1 if failed.

- Insert token's data
    - Opcode = 0x21
    - Add or replace a data into a token
    - Return 0 if tree conformal, 1 if not.


### Delete

- Delete token
    - Opcode = 0x30
    - Delete a node in the tree, its information and its data if appended.
    - Append existing children in the tree.
    - Return 0 if operation was successfull, 1 if failed.

- Delete data in token
    - Opcode = 0x31
    - Delete the data block content linked to a node.
    - Return 0 if operation was successfull, 1 if failed.

- Delete children of a token
    - Opcode = 0x32
    - Delete children of a node
    - Return 0 if operation was successfull, 1 if failed.

- Delete left child of a token
    - Opcode = 0x33
    - Delete left child and its children
    - Return 0 if operation was successfull, 1 if failed.

- Delete right child of a token
    - Opcode = 0x34
    - Delete right child and its children
    - Return 0 if operation was successfull, 1 if failed.

### Utility

- Create tree
    - Opcode = 0x40
    - Read genesis address and create a root node to build a tree
    - Return status = 0 if successful, 1 if failed to access memory.

- (Verify tree conformance) (TBD)
    - Opcode = 0x41
    - Parse the tree and ensure it respects the binary tree paradigm.
    - Return 0 if tree conformal, 1 if not.

- (Reorder tree) (TBD)
    - Opcode = 0x42
    - Reoder a non-conformal tree.
    - Return 0 if tree conformal, 1 if not.

- Get size of tree
    - Opcode = 0x43
    - Parse the tree and count the number of nodes.
    - If token specified, only discover its size, not the tree size.
    - Return the number of nodes.

- Get depth of tree
    - Opcode = 0x44
    - Parse the tree and count the number of layers.
    - If token specified, only discover its depth, not the tree depth.
    - Return the number of layer.


## Memory Structure

- Parameters to define:
    - `ADEPTH`: The memory depth (**integer**).
    - `AWIDTH`: The memory address width. Derived from memory depth, >= log2(depth), (**integer**).
    - `DWIDTH`: The memory data width from 1 to 1024 bits (**integer**).
    - `GENESIS_ADDR`: The genesis's node address (`AWIDTH` bits) (**integer**).
    - `STORE_DATA`: If nodes store or not payload along a token. (**boolean**)
    - `STORE_DIGEST`: Compute node digest. Disabling it speed-up the IP. (**boolean**)


### Node Structure

- Token (`DWIDTH` bits)
- Parent node address (`AWIDTH` bits)
- Left child address (`AWIDTH` bits)
- Right child address (`AWIDTH` bits)
- Information (`DWIDTH` bits)
    - has payload (1 bit)
    - is genesis block (1 bit)
    - has left child (1 bit)
    - has right child (1 bit)
    - is smallest child (1 bit)
- Payload (`DWIDTH` bits) (**optional**)
- Metadata (`DWIDTH` bits) (**optional**)
- Node digest (hash of all the other fields) (`DWIDTH` bits) (**optional**)


### Register Map

Register map can be accessed from 32 bits wide only AXI4-lite interface.
Address are indicated with byte oriented

- Mailbox (Address 0) (`DWIDTH` bits) (**Read/Write**)
    - A register to verify AXI4-lite interface completion
    - User only, never used by the IP

- Genesis’s node address (Address 4) (`AWIDTH` bits) (*Read/Write*)
    - The genesis block address
    - IP auto-restarts if updated after boot

- Restart the IP (Address 8) (1 bit) (**Read/Write**)
    - Apply the restart procedure.
    - Auto set to 0 once restart is finished, remains asserted during procedure
    - All IP's interfaces remain unavailable during this operation.

- Memory access error (Address 12 - offset 0) (1 bit) (**Read-only**))
    - Indicate a problem during a previous memory access (last over 1 ms)

- Memory full (1 bit) (Address 12 - offset 1) (**Read-only**))
    - Indicate no more memory space remains for future storage

- Under operation (1 bit) (Address 12 - offset 2) (**Read-only**))
    - IP is processing a user request
    - Return 1 if write access issued in these fields

- Operation under execution (8 bits) (Address 8 - offset 0) (**Read-only**))
    - Provides the opcode of the operation under execution

- Under maintenance (1 bit) (Address 8 - offset 8) (**Read-only**))
    - IP is unavailable, applying an internal operation

- Upper bits reserved (**Reserved**))
    - Reserved for future update or internal usage.
    - Return error if access issued in these fields

## Command Algorithms

### Startup

1. Write, then read an empty address to check memory access. Go in ERROR state if failling.
2. Check genesis block format. If not conform, create a new one.
3. Go to IDLE state, ready to receive requests.

### Insert token

1. Check memory is not full. If full return the appropriate status code.
2. Check genesis is used, if not use its address and go to `Step 3`, else go to `Step 4`
3. If use genesis block, simply store the token and go back `Step 1`
4. Read genesis block and compare its token's value to insert:
    - If new token is smaller, store left child address and continue to `Step 5`
    - If new token is biggest, store right child address and continue to `Step 5`
5. Read next block address and compare its token's value to insert.
    - If block is empty or partially used, use it to store the incoming token:
        - If new token is smaller than block's token, store it on left position. Go back to `Step1`
        - If new token is bigger than block's token, store it on right position. Go back to `Step1`
    - Else if block's children can't be used because already linked in the tree:
        - If new token is smaller, store left child address and repeat `Step 5`
        - If new token is biggest, store right child address and repeat `Step 5`


