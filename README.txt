================================================================                
FILE: README.txt
PROJECT: Timer Peripheral Verification Environment
AUTHOR: Peleg Shay
DATE: December 19, 2025
================================================================

1. PROJECT OVERVIEW
-------------------
This environment is a Constrained-Random Verification (CRV) testbench 
implemented in SystemVerilog. It is designed to verify a Timer Peripheral 
featuring a request/grant (REQ/GNT) handshake protocol, programmable 
load values, status monitoring, and auto-reload capabilities.

2. FILE STRUCTURE & ARCHITECTURE
--------------------------------
The project is organized into modular components to ensure reusability:

- tb_top.sv: The top-level module. Handles clock/reset generation [cite: 60, 62] 
  and instantiates the DUT, Interface, and Assertions[cite: 68, 70].
- TimerTest.sv: The top-level test class. Orchestrates the environment by 
  building components and running the test sequences[cite: 74].
- timer_interface.sv: Defines the bus signals (req, gnt, addr, data) [cite: 80] 
  and synchronous clocking blocks for Driver and Monitor[cite: 86, 90].
- TimerGenerator.sv: Generates constrained-random transactions [cite: 154] 
  and sends them to the Driver via a mailbox[cite: 165].
- TimerDriver.sv: Implements the REQ/GNT handshake protocol [cite: 181] 
  and drives data onto the virtual interface[cite: 184].
- TimerMonitor.sv: Passively samples the bus [cite: 118] and converts 
  physical signals into TLM objects for the Checker[cite: 128].
- TimerChecker.sv: Houses the Reference Model [cite: 35] to predict register 
  states and compare actual read data against expected values[cite: 55].
- TimerCoverage.sv: Collects functional coverage on registers, operation 
  modes (One-Shot/Auto-Reload), and status flags[cite: 132, 140].
- timer_assertions.sv: Contains SystemVerilog Assertions (SVA) for 
  protocol timing and functional logic validation[cite: 93].

3. DATA MODEL (Transaction Classes)
-----------------------------------
To support clean OOP design, we used a class hierarchy for bus activity:

- TimerBaseTransaction: The parent class containing common fields like 
  address and transaction kind (Read/Write).
- TimerWriteTransaction: Extends the base class for WRITE operations[cite: 195]. 
  It includes specific logic for handling WDATA[cite: 198].
- TimerReadTransaction: Extends the base class for READ operations[cite: 103]. 
  It includes logic for capturing and displaying RDATA[cite: 106].

4. DESIGN CHOICES & RATIONALE
------------------------------
- Centralized Test Control (TimerTest): By using a Test class, we separate 
  the "How to test" (Generator/Driver) from the "What to test" (Test class). 
  This allows us to easily create new test cases by simply swapping 
  the Generator's constraints without changing the infrastructure.
  
- Polymorphism: The Driver and Monitor handle 'TimerBaseTransaction' handles 
  but use '$cast' to identify if the specific object is a Read or Write[cite: 123, 185]. 
  This makes the code flexible and scalable for future register additions.

- Reference Modeling: The Checker maintains an internal 'TimerReferenceModel' 
  to track register updates[cite: 10]. This allows us to verify the DUT's 
  state even when the bus is idle.

5. CRITICAL FINDINGS (RTL BUGS IDENTIFIED)
------------------------------------------
1. GNT Latency Violation: GNT asserted 4 cycles after REQ (Spec says <=3)[cite: 96].
2. Expiration Delay: The expired_flag rises 1 cycle after counter hits zero[cite: 99].
3. W1C Logic Failure: Writing '1' to Status (0x08) does not clear the flag[cite: 102].

================================================================