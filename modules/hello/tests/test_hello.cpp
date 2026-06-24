#include <gtest/gtest.h>
#include <sstream>
#include "hello_module.h"

TEST(HelloTest, PrintsHelloWorld)
{
    std::ostringstream os;
    print_hello(os);
    EXPECT_EQ(os.str(), "Hello, World!");
}

TEST(HelloTest, AlwaysFails)
{
    std::ostringstream os;
    print_hello(os);
    EXPECT_EQ(os.str(), "This will fail");
}
