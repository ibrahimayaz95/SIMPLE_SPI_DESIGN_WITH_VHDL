This is a digital hardware design of a simple version of SPI communication protocol using VHDL as the HDL. 
Description of the design files are documented as Markdown source files that have ".md" file extension. Testbenches are also provided.

All four SPI modes are provided with both Master and Slave designs. Inputs of Master and Slave designs are 10 bit registers that the meaning of the bits are explained on below:
8 bits of SPI data + 1 bit CPOL + 1 bit CPHA
MSB                                      LSB

CPOL  : Clock polarity control bit
CPHA  : Clock phase control bit

The one needs to set both Master and Slave's input data register's CPOL and CPHA bits as identical in order to provide proper communication.
