// Cale Woodward
// Greg Stitt
// University of Florida
//
// vector_add.cpp
//
// This SYCL program will create a parallel (vectorized) version of the following
// sequential code:
//
// for (int i=0; i < VECTOR_SIZE; i++) {
//   out[i] = in1[i] + in2[i];
//
// In this version of the code, we shorten all the code a little bit using std as
// a default namespace, and using sycl:: instead of cl::sycl.

#include <iostream>
#include <vector>

#include <CL/sycl.hpp>

// CHANGES FROM PREVIOUS CODE
// NOTE: Some SYCL examples have to explicitly define this shortened namespace.
// On the DevCloud installation, this shortened namespace is already defined.
// If you get errors in other environments saying that namespace sycl is undefined,
// uncomment the following line.
//
// namespace sycl = cl::sycl;

using namespace std;

const int VECTOR_SIZE = 1000;

class vector_add;

int main(int argc, char* argv[]) { 
  
  cout << "Performing vector addition...\n"
       << "Vector size: " << VECTOR_SIZE << endl;

  vector<int> in1_h(VECTOR_SIZE);
  vector<int> in2_h(VECTOR_SIZE);
  vector<int> out_h(VECTOR_SIZE);
  vector<int> correct_out(VECTOR_SIZE);

  for (size_t i=0; i < VECTOR_SIZE; i++) {
    in1_h[i] = i;
    in2_h[i] = i;
    out_h[i] = 0;
    correct_out[i] = i + i;
  }

  // CHANGES FROM PREVIOUS EXAMPLE
  // Instead of just creating a new scope, it is usually a good idea to enclose the
  // device code in a try block to catch exceptions. This also creates a new scope
  // while enabling exception handling.
  try {
    sycl::queue queue(sycl::default_selector_v);
    
    sycl::buffer<int, 1> in1_buf {in1_h.data(), sycl::range<1>(in1_h.size()) };
    sycl::buffer<int, 1> in2_buf {in2_h.data(), sycl::range<1>(in2_h.size()) };
    sycl::buffer<int, 1> out_buf {out_h.data(), sycl::range<1>(in2_h.size()) };
    
    queue.submit([&](sycl::handler& handler) {

	sycl::accessor in1_d(in1_buf, handler, sycl::read_only);
	sycl::accessor in2_d(in2_buf, handler, sycl::read_only);
	sycl::accessor out_d(out_buf, handler, sycl::write_only);

	handler.parallel_for<class vector_add>(sycl::range<1> { in1_h.size() }, [=](sycl::id<1> i) {
	    out_d[i] = in1_d[i] + in2_d[i];
	  });

      });

    queue.wait();
  }
  catch (sycl::exception& e) {
    cout << e.what() << endl;
    return 1;
  }
  
  cout << "Operation complete:\n"
       << "[" << in1_h[0] << "] + [" << in2_h[0] << "] = [" << out_h[0] << "]\n"
       << "[" << in1_h[1] << "] + [" << in2_h[1] << "] = [" << out_h[1] << "]\n"
       << "...\n"
       << "[" << in1_h[VECTOR_SIZE - 1] << "] + [" << in2_h[VECTOR_SIZE - 1] << "] = [" << out_h[VECTOR_SIZE - 1] << "]\n"
       << endl;

  if (out_h == correct_out) {
    cout << "SUCCESS!" << endl;
  }
  else {
    cout << "ERROR: Execution failed." << endl;
  }
  
  return 0;
}
