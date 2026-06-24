#include "hello_module.h"
#include "hello.h"

void print_hello(std::ostream& os)
{
    os << hello();
}
