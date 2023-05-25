// Greg Stitt
// University of Florida
//
// matrix_add_dynamic3.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code, which performs matrix addition:
//
// for (int i=0; i < NUM_ROWS; i++)
//   for (int j=0; j < NUM_COLS; j++) 
//     out[i][j] = in1[i][j] + in2[i][j];
//
// This implementation shows a 3rd alternative to using dynamic 2D
// arrays without having to use manual row-major ordering computations.

#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <string>

#include <CL/sycl.hpp>

class matrix_add;


// CHANGES FROM PREVIOUS VERSION
// Here we introduce a matrix class that internally stores the
// matrix in a 1D array, but overloads the [] operator so that we
// can use [][] notication to access it in a 2D manner.
class Matrix {

public:
  Matrix(size_t rows, size_t cols) : num_rows(rows), num_cols(cols) {
    matrix = new int[rows*cols];
  }

  ~Matrix() {
    delete[] matrix;
  }

  // NOTE: this only does error checking for the row bounds.
  // Column bounds could be checked by also creating a row
  // class that overloads [].
  int* operator[](int i) {
    if (i >= num_rows) {
      throw std::runtime_error("Invalid row accessed");
    }
    
    return matrix + i*num_cols;
  }

  // Returns an integer pointer to start of the matrix, similarly
  // to std::vector.
  int *data() {
    return matrix;
  }
  
private:
  int *matrix;
  size_t num_rows;
  size_t num_cols; 
};


void print_usage(const std::string &name) {

  std::cout << name << " num_rows num_cols (both must be positive)." << std::endl;
}

int main(int argc, char* argv[]) { 

  size_t num_rows;
  size_t num_cols;
  
  if (argc != 3) {
    print_usage(argv[0]);
    return 1;    
  }
  else {

    int rows = atoi(argv[1]);
    int cols = atoi(argv[2]);
    if (rows < 1 || cols < 1) {
      print_usage(argv[0]);
      return 1;
    }

    num_rows = rows;
    num_cols = cols;
  }

  // CHANGES FROM PREVIOUS EXAMPLE
  // Here, we instanitate Matrix objects instead of int* or vectors.
  Matrix in1_h(num_rows, num_cols);
  Matrix in2_h(num_rows, num_cols);
  Matrix out_h(num_rows, num_cols);
  Matrix correct_out(num_rows, num_cols);
  
  // CHANGES FROM PREVIOUS VERSION
  // With the Matrix objects, we can use the original 2D array indexing syntax.
  for (size_t i=0; i < num_rows; i++) {for (size_t j=0; j < num_cols; j++) {
      in1_h[i][j] = i;
      in2_h[i][j] = j;
      out_h[i][j] = 0;
      correct_out[i][j] = i + j;
    }
  }

  try {
    cl::sycl::queue queue(cl::sycl::default_selector_v);

    // This code can stay the same due to the data() method of the Matrix class.
    cl::sycl::buffer<int, 2> in1_buf(in1_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> in2_buf(in2_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    cl::sycl::buffer<int, 2> out_buf(out_h.data(), cl::sycl::range<2> {num_rows, num_cols} );
    
    queue.submit([&](cl::sycl::handler& handler) {

	cl::sycl::accessor in1_d(in1_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor in2_d(in2_buf, handler, cl::sycl::read_only);
	cl::sycl::accessor out_d(out_buf, handler, cl::sycl::write_only);

	handler.parallel_for<class matrix_add>(cl::sycl::range<2> { num_rows, num_cols }, [=](cl::sycl::id<2> id) {
	    size_t x = id[0];
	    size_t y = id[1];
	    out_d[x][y] = in1_d[x][y] + in2_d[x][y];
	  });

      });

    queue.wait_and_throw();
  }
  catch (cl::sycl::exception& e) {
    std::cout << e.what() << std::endl;
    return 1;
  }
  
  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      std::cout << std::setw(5) << out_h[i][j] << " ";
    }
    std::cout << std::endl;
  }

  for (size_t i=0; i < num_rows; i++) {
    for (size_t j=0; j < num_cols; j++) {
      if (out_h[i][j] != correct_out[i][j]) {
	std::cout << "ERROR: Execution failed." << std::endl;
	return 1;
      }
    }
  }
  
  std::cout << "SUCCESS!" << std::endl;
    
  return 0;
}
