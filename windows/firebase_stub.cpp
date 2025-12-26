// Stub library to satisfy Firebase Release build dependencies
// This provides minimal implementations for Firebase C++ SDK symbols

#include <cstdlib>
#include <crtdbg.h>

// Provide debug runtime symbols that Release build expects
extern "C" {
    
    // These are the missing symbols from the Debug libraries
    int __cdecl _CrtDbgReport(int reportType, const char* filename, int linenumber, const char* moduleName, const char* format, ...) {
        return 0; // Return success
    }
    
    void* __cdecl _calloc_dbg(size_t count, size_t size, int blockType, const char* filename, int linenumber) {
        return calloc(count, size); // Use regular calloc
    }
    
    void __cdecl _invalid_parameter(const wchar_t* expression, const wchar_t* function, const wchar_t* file, unsigned int line, uintptr_t reserved) {
        // Do nothing - just ignore invalid parameters
    }
    
    void __cdecl _CrtSetReportMode(int reportType, int reportMode) {
        // Do nothing - ignore debug report mode
    }
    
    void __cdecl _CrtSetReportFile(int reportType, void* reportFile) {
        // Do nothing - ignore debug report file
    }
    
    // Memory allocation stubs
    void* __cdecl operator new(size_t size) {
        return malloc(size);
    }
    
    void __cdecl operator delete(void* ptr) {
        free(ptr);
    }
    
    void* __cdecl operator new[](size_t size) {
        return malloc(size);
    }
    
    void __cdecl operator delete[](void* ptr) {
        free(ptr);
    }
}