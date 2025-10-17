typedef unsigned int u32;

/* UART base address — match this with your Verilog memory map */
#define UART0 ((volatile unsigned char*)0x10000000U)

/* --- Declare uart_putc before using it --- */
static void uart_putc(char c)
{
    *UART0 = (unsigned char)c;
}

/* --- Now uart_puts can use uart_putc --- */
static void uart_puts(const char *s)
{
    while (*s)
        uart_putc(*s++);
}

int main(void)
{
    volatile u32 a = 5;
    volatile u32 b = 7;
    volatile u32 c = a + b;

    uart_puts("RES=");

    /* convert number to ASCII manually */
    char buf[12];
    int i = 0;
    unsigned int temp = c;
    if (temp == 0)
        uart_putc('0');
    else
    {
        while (temp > 0)
        {
            buf[i++] = '0' + (temp % 10);
            temp /= 10;
        }
        while (i--)
            uart_putc(buf[i]);
    }
    uart_putc('\n');

    /* store result in memory at address 0x200 for debug */
    volatile u32 *result_mem = (u32 *)0x200;
    *result_mem = c;

    while (1)
        asm volatile("wfi"); // wait-for-interrupt idle loop
    return 0;
}

