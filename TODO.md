# DOC

- [ ] Write registers into tables
- [ ] Write commands into tables
- [ ] Describe algorithms with draws


# DONE

- [X] Add logger in the core. Print statement during code execution and grep
      them with run.sh
- [X] Support insert
    - [X] can insert root node
    - [X] can insert a token
- [X] Support depth first search
- [X] Provide completion for insert commands

# DESIGN

- [-] Support delete
    - [X] Support a deletion with O or 1 child
    - [-] Support a deletion with two children
    - [ ] Support root node deletion
- [ ] Enhance tree\_ready to be toggle off when root node is deleted
- [ ] Support timeout
- [ ] Complete a request when accessing an empty tree from interface, not
      from engine
- [ ] Implement CSR and connect it on modules
    - root node address needs to come from it.
    - if root deleted and memory is fragmented, this address need to
      come first when an address is req
- [ ] Enhance tree space manager and support defrag
- [ ] Make RAM access synchronous, add a scfifo
    - [ ] Make possible to choose between async and sync interface
    - [ ] Outstanding request configurable
- [ ] Cache layer:
    - anticipate next read based on read address and command
    - store last written address to avoid to read again
    - use a local CAM
- [ ] List error cases encountered by BSTer:
    - try to insert while tree is not initialized with a root node
    - digest is not valid while reading a node
    - unsupported command issued
- [ ] Create a design with a SOC (using LiteX) and add as peripheral
- [ ] Implement further command by adding a sequencer to combine existing
      commands and propose new features. With a CPU? Thru an API?
- [ ] Support completion with status = 1 if commabnd issued is not supported
- [ ] Support heap creation (forward or backward ordering)
- [ ] Support sort command
- [ ] Support shallow copy
- [ ] Replace RAM model with a real one (Use XLZ AXI RAM?)
- [ ] Support error for any memory failure when inserting or deleting tokens


# BACKLOG

- Support breadth first search
- Put in place in-house benchmarking into the core
- Support signed values?
- Test conformance: use sort or shallow copy, data must arrives in right order
  meaning its well constructed
- Support any AXI4 interface width


# STUDY

- study in depth binary tree theory

- Consider ML for sorting:

    - https://blog.acolyer.org/2020/10/19/the-case-for-a-learned-sorting-algorithm/
    - https://en.wikipedia.org/wiki/German_tank_problem

- study stdlib C or python implementaton of array and dict

- Applications:
    - Use in decison tree
    - Fuzzy matching
