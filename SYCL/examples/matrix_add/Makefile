objects = matrix_add1 matrix_add2 matrix_add_dynamic1 matrix_add_dynamic2 matrix_add_dynamic3

all: $(objects)

matrix_add_bad: matrix_add_bad.cpp
	icpx -fsycl matrix_add_bad.cpp -o matrix_add_bad -Wall -O3

$(objects): %: %.cpp
	icpx -fsycl $< -o $@ -Wall -O3

clean:
	rm -f $(objects) matrix_add_bad
