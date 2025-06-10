# Makefile para systolic_ref.cpp

# Variables
CXX = g++
CXXFLAGS = -std=c++17 -O2
TARGET = systolic_ref_4x4
SRC = systolic_4x4.cpp

# Regla por defecto
all: $(TARGET)

# Compilar
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(TARGET)

# Ejecutar
run: $(TARGET)
	./$(TARGET)

# Limpiar archivos generados
clean:
	rm -f $(TARGET)
