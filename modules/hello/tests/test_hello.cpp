#include <gtest/gtest.h>
#include "hello.h"

TEST(HelloTest, ReturnsHelloWorld)
{
    EXPECT_EQ(hello(), "Hello, World!");
}
