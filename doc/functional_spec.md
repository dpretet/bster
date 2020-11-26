# Functional Specification


## Summary

- [Introduction](#Introduction)
- [Commands](#Commands)
- [Node Structure](#Node-Structure)
- [Register map](#Control-/-Status-Register-Map)
- [Command Algorithms](#Command-Algorithms)


## Introduction

- [Binary tree overview](https://en.wikipedia.org/wiki/Binary_tree) and its advantages.
- [Usage example](https://stackoverflow.com/questions/2130416/what-are-the-applications-of-binary-trees).
    - Hash tree
    - Huffman coding
    - Radix tree
    - Merkle tree
    - Prefix tree
- [Binary search tree](https://en.wikipedia.org/wiki/Binary_search_tree)

Spec:

- RTL description in SystemVerilog
- [AMBA4](https://developer.arm.com/architectures/system-architectures/amba/documentation) compliant.
- [FPGA](https://en.wikipedia.org/wiki/Field-programmable_gate_array) agnostic.
- Support any memory type, depth and size being AXI4 compliant. Users can plug
  their own model if necessary.
- The IP provides 3 interfaces:
    - 1 AXI4-lite interface to access the [register map](#Register-Map).
    - 1 AXI4-Stream slave to request [operations](#Commands) on the tree.
    - 1 AXI4-Stream master to get back command's completion.
- A node in the tree uses the `token` terminology to name an element to store.
  A token is considered as an abstract value and can represent anything:
    - It's interpreted as an **address** to locate a node.
    - Can mean address, data, id, ... the meaning depends of the
      application.
    - All operations parsing the tree rely on this field.
    - A token can embbed payload
- Support 3 basic operations:
    - Insert
    - Delete
    - [Search](https://en.wikipedia.org/wiki/Tree_traversal). Two modes available:
        - depth-first order (as pre-order, in-order or post-order)
        - breadth-first order (also named level order)
- Advanced operation: shallow copy
    - can copy the content of the tree in another memory location
      and reorder it to create min or max heap tree
- Support digest computation:
    - single node digest: node content is used to create a unique digest
    - merkle tree like: node and its two children are used to create the digest
      in the node

## Commands

All commands are issued by the user on the AXI4S slave interface.

All commands are coded over 8 bits.

All commands' completion and status are driven on the AXI4S master interface by
the IP core.

Command interface:
- MSB: the command coded with 8 bits
- LSB: the token value and its optional data payload

The command interface must be sized to enclose the command, the token and
the payload. If not wide enough, the IP can't work properly. For instance,
if the token is 16 bits wide and the data 32 bits wide, the interface must be
at least 52 bits. Token and payload width are defined with respectively
`TOKEN_WIDTH` and `PAYLOAD_WIDTH`.

    (TOKEN_WIDTH+PAYLOAD_WIDTH+8) <= AXI4S_WIDTH

Completion interface:
- MSB: the command status (1 bit)
- LSB: the payload (content depends the command issued)

Both the interfaces use the same parameter (`AXI4S_WIDTH`) to be sized.

    (PAYLOAD_WIDTH+1) <= AXI4S_WIDTH

### Search commands

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

### Insert commands

- Insert token
    - Opcode = 0x20
    - Insert a new token, optionally a data associated
    - Return 0 if operation was successfull, 1 if failed.

- Insert token's data
    - Opcode = 0x21
    - Add or replace a data into a token
    - Return 0 if tree conformal, 1 if not.

### Delete commands

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

### Utility commands

- Check tree conformance
    - Opcode = 0x40
    - Parse the tree and ensure it respects the binary tree paradigm.
    - Return 0 if tree conformal, 1 if not.

- Shallow copy tree
    - Opcode = 0x41
    - Copy into a new memory place the tree
    - Return 0 if operation is OK, 1 otherwse.

- Get size of tree
    - Opcode = 0x42
    - Parse the tree and count the number of nodes.
    - If token specified, only discover its size, not the tree size.
    - Return the number of nodes.

- Get depth of tree
    - Opcode = 0x43
    - Parse the tree and count the number of layers.
    - If token specified, only discover its depth, not the tree depth.
    - Return the number of layer.

- Sort tree
    - Opcode = 0x44
    - Parse the tree and stream back its content, sorted from min to max value
    - Return an array like data stream.


## Node Structure

Into BST engine, a node is read/write to memory on a single word. Follow a
description from LSB to MSB of a node.

- Information (8 bits)
    - reserved (5 bits)
    - is root block (1 bit)
    - has left child (1 bit)
    - has right child (1 bit)
- Token (`DWIDTH` bits)
- Parent node address (`AWIDTH` bits)
- Right child address (`AWIDTH` bits)
- Left child address (`AWIDTH` bits)
- Payload (`DWIDTH` bits)
- Node digest (hash of all the other fields) (`DWIDTH` bits) (**optional**)


## Control / Status Register Map

Register map can be accessed from 32 bits wide only AXI4-lite interface.
Address are indicated with byte oriented notation.

- Mailbox (Address 32'h00 - offset 0) (32 bits) (**Read/Write**)
    - A register to verify AXI4-lite interface responsiveness
    - User only, never used by the IP

- Root node address (Address 32'h04 - offset 0) (`AWIDTH` bits) (**Read/Write**)
    - The root node LSB address
    - User needs to apply a reset procedure if updated

- Root node address (Address 32'h08 - offset 0) (`AWIDTH` bits) (**Read/Write**)
    - The root node MSB address
    - If address width is smaller or equal to 32 bits, must be tied to 0
    - User needs to apply a reset procedure if updated

- Restart the IP (Address 32'h0C - offset 0) (1 bit) (**Read/Write**)
    - Apply the restart procedure.
    - Auto set to 0 once restart is finished, remains asserted during procedure
    - All IP's interfaces remain unavailable during this operation.

- Memory access error (Address 32'h0C - offset 1) (1 bit) (**Read-only**)
    - Indicate a problem during a previous memory access (last over 1 ms)
    - Return 1 if write access issued in these fields

- Memory full (Address 32'h0C - offset 2) (1 bit) (**Read-only**)
    - Indicate no more memory space remains for future storage
    - Return 1 if write access issued in these fields

- Under operation (Address 32'h0C - offset 3) (1 bit) (**Read-only**)
    - IP is processing a user request
    - Return 1 if write access issued in these fields

- Under maintenance (Address 32'h0C - offset 4) (1 bit) (**Read-only**)
    - IP is unavailable, applying an internal operation
    - Return 1 if write access issued in these fields

- Operation under execution (Address 32'h0C - offset 5) (8 bits) (**Read-only**)
    - Provides the opcode of the operation under execution
    - Return 1 if write access issued in these fields

- Upper bits reserved (**Reserved**))
    - Reserved for future update or internal usage.
    - Return error if read/write access issued in these fields
