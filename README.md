APB UVM Verification Environment

This repository contains a fully parameterized UVM-based verification environment for the AMBA APB protocol, designed with flexibility, reusability, and scalability in mind. The environment is capable of verifying multiple APB configurations simultaneously within a single testbench.

Key Features
1. Parameterized UVM Environment

The entire APB environment is built using SystemVerilog parameterized classes, allowing critical protocol attributes such as address width and data width to be configured at compile time. This enables the same environment to be reused for different APB designs without modifying the core verification components.

2. Configurable APB Agent

The APB agent is fully parameterized and includes:

APB driver

APB monitor

APB sequencer

Multiple instances of the APB agent can be created inside the environment, each with different parameter values, making it possible to verify heterogeneous APB slaves or masters in parallel.

3. Sequencer with Arbitration Support

The sequencer is designed to arbitrate between multiple sequences, enabling concurrent stimulus generation such as:

Read/write traffic from different sources

Directed and random sequences running together

Stress and corner-case testing

This allows realistic and complex APB traffic patterns to be exercised.

4. Functional Coverage Model

A comprehensive functional coverage model is integrated into the environment to ensure thorough verification. Coverage points include:

APB read and write operations

Address and data ranges

Protocol-specific handshaking and timing behavior

This helps in measuring verification completeness and identifying untested scenarios.

5. Top-Level Interface Configuration

The APB virtual interfaces are set from the testbench top and passed down to each agent using the UVM configuration database. Each agent instance connects to its corresponding interface with matching parameter values, ensuring correct signal mapping and clean separation between design and verification components.

6. Scalable and Reusable Architecture

The environment is designed to:

Easily add or remove APB agent instances

Support different parameter combinations without code duplication

Integrate smoothly into larger SoC-level verification environments

<img width="1086" height="710" alt="image" src="https://github.com/user-attachments/assets/a6cdadce-5ad3-4f29-9794-65eadedbd25a" />
