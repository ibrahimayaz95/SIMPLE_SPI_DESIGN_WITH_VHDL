# Entity: SPI_SLAVE 

- **File**: SPI_SLAVE.vhd
## Diagram

![Diagram](SPI_SLAVE.svg "Diagram")
## Generics

| Generic name | Type    | Value       | Description                 |
| ------------ | ------- | ----------- | --------------------------- |
| CLK_FREQ     | integer | 100_000_000 | Clock frequency             |
| BAUDRATE     | integer | 115_200     | SPI baudrate                |
| DATA_LIMIT   | integer | 8           | Selected SPI data bit width |
## Ports

| Port name | Direction | Type                                               | Description               |
| --------- | --------- | -------------------------------------------------- | ------------------------- |
| CLK       | in        | std_logic                                          | Clock port                |
| RESET     | in        | std_logic                                          | Reset port                |
| MOSI      | in        | std_logic                                          | Master out Slave in port  |
| SS        | in        | std_logic                                          | Slave Select port         |
| SCK       | in        | std_logic                                          | Generated SPI clock port  |
| SLIN      | in        | std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) | Parallel data input port  |
| MISO      | out       | std_logic                                          | Master in Slave Out port  |
| SLOUT     | out       | std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) | Parallel data output port |
| SLREADY   | out       | std_logic                                          | Slave ready port          |
| SLDONE    | out       | std_logic                                          | Slave done port           |
## Signals

| Name         | Type                                               | Description                                 |
| ------------ | -------------------------------------------------- | ------------------------------------------- |
| PS           | state_type                                         | Present and Next State signal's declaration |
| NS           | state_type                                         | Present and Next State signal's declaration |
| CPOL_REG     | std_logic                                          | Clock polarity control signal               |
| CPHA_REG     | std_logic                                          | Clock phase control signal                  |
| SS_REG       | std_logic                                          | Register for the Slave select               |
| MOSI_REG     | std_logic_vector ((DATA_LIMIT - 1) downto 0)       | Shift register for the MOSI                 |
| MISO_REG     | std_logic_vector ((DATA_LIMIT - 1) downto 0)       | Shift register for the MISO                 |
| MISO_TEMP    | std_logic_vector ((DATA_LIMIT - 1) downto 0)       | Register for the input data                 |
| SLOUT_REG    | std_logic_vector (((DATA_LIMIT + 2) - 1) downto 0) | Register for the output data                |
| DATA_COUNTER | integer                                            | Counter signal                              |
## Types

| Name       | Type                                                                                                   | Description         |
| ---------- | ------------------------------------------------------------------------------------------------------ | ------------------- |
| state_type | (S_IDLE,<br><span style="padding-left:20px"> S_TRANSCEIVE,<br><span style="padding-left:20px"> S_STOP) | Type for the states |
## Processes
- FSM_SYNC: ( CLK, RESET )
- MAIN: ( RESET, SS_REG, PS, SCK, CLK )
