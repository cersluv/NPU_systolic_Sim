#include <iostream>
#include <array>
#include <cstdint>
#include <iomanip>
#include <cassert>

// Dimensión del arreglo (4×4 PEs)
constexpr int N = 4;
using DataT = int16_t;   // 16-bit signed fixed-point
using AccT  = int32_t;   // Acumulador de 32 bits

// Alias para las tres matrices
using MatA = std::array<std::array<DataT, N>, N>;
using MatB = std::array<std::array<DataT, N>, N>;
using MatC = std::array<std::array<AccT,  N>, N>;

// Cada Processing Element guarda su a, b y suma parcial
struct PE {
    DataT a = 0, b = 0;
    AccT  psum = 0;
};

// Función auxiliar para imprimir una matriz
template<typename T>
void print_mat(const std::array<std::array<T,N>,N>& M, char name) {
    std::cout << "   Mat " << name << ":\n";
    for(int i=0;i<N;++i) {
        std::cout << "    ";
        for(int j=0;j<N;++j)
            std::cout << std::setw(6) << M[i][j] << ' ';
        std::cout << "\n";
    }
    std::cout << "\n";
}

// Simula la multiplicación de matrices A×B usando un arreglo sistólico NxN
void simulate_systolic(const MatA& A, const MatB& B, MatC& C, bool debug=false, bool stepping=false) {
    std::array<std::array<PE,N>,N> mesh{};
    int total_cycles = 3*N - 2;

    if (stepping) {
        std::cout << "=== MODO STEPPING ACTIVADO ===\n";
        std::cout << "Se ejecutarán " << total_cycles << " ciclos en total.\n";
        std::cout << "Presiona ENTER para avanzar cada ciclo...\n\n";
    }

    for(int t=0; t<total_cycles; ++t) {
        // inyecta A en columna 0 / B en fila 0 (ó ceros)
        for(int i=0;i<N;++i) {
            int k = t - i;
            mesh[i][0].a = (0<=k && k<N) ? A[i][k] : 0;
        }
        for(int j=0;j<N;++j) {
            int k = t - j;
            mesh[0][j].b = (0<=k && k<N) ? B[k][j] : 0;
        }

        // buffers para shift
        std::array<std::array<DataT,N>,N> nextA{};
        std::array<std::array<DataT,N>,N> nextB{};

        // cada PE multiplica y acumula, y programa su shift
        for(int i=0;i<N;++i){
            for(int j=0;j<N;++j){
                auto &pe = mesh[i][j];
                pe.psum += AccT(pe.a)*AccT(pe.b);
                if(j+1<N) nextA[i][j+1] = pe.a;
                if(i+1<N) nextB[i+1][j] = pe.b;
            }
        }
        // actualiza a/b
        for(int i=0;i<N;++i)
            for(int j=0;j<N;++j){
                mesh[i][j].a = nextA[i][j];
                mesh[i][j].b = nextB[i][j];
            }

            if (debug) {
                // extraer tres matrices auxiliares para imprimir
                std::array<std::array<DataT,N>,N> MA{}, MB{};
                std::array<std::array<AccT, N>,N>  MP{};
                for(int i=0;i<N;++i)
                    for(int j=0;j<N;++j){
                        MA[i][j] = mesh[i][j].a;
                        MB[i][j] = mesh[i][j].b;
                        MP[i][j] = mesh[i][j].psum;
                    }
                    std::cout << "=== Cycle t="<<t<<" ===\n";
                print_mat(MA,'A');
                print_mat(MB,'B');
                print_mat(MP,'P');
                
                if (stepping) {
                    std::cout << "Presiona ENTER para continuar al siguiente ciclo...";
                    std::cin.get();
                    std::cout << "\n";
                }
            }
    }

    // vuelca resultados
    for(int i=0;i<N;++i)
        for(int j=0;j<N;++j)
            C[i][j] = mesh[i][j].psum;
}

int main() {
    // Matrices hardcodeadas para prueba de 4×4
    constexpr MatA A = {{
        {{  1,  2,  3,  4 }},
        {{  5,  6,  7,  8 }},
        {{  9, 10, 11, 12 }},
        {{ 13, 14, 15, 16 }}
    }};

    constexpr MatB B = {{
        {{ 16, 15, 14, 13 }},
        {{ 12, 11, 10,  9 }},
        {{  8,  7,  6,  5 }},
        {{  4,  3,  2,  1 }}
    }};

    // Resultado teórico de A x B
    constexpr MatC C_expected = {{
        {{ 80,  70,  60,  50 }},
        {{240, 214, 188, 162 }},
        {{400, 358, 316, 274 }},
        {{560, 502, 444, 386 }}
    }};

    // Mostrar matrices de entrada
    std::cout << "=== SIMULADOR ARREGLO SISTÓLICO 4×4 ===\n\n";
    print_mat(A, 'A');
    print_mat(B, 'B');
    print_mat(C_expected, 'E');

    // Selección del modo de ejecución
    char choice;
    bool debug = false;
    bool stepping = false;
    
    std::cout << "Selecciona el modo de ejecución:\n";
    std::cout << "1. Ejecución completa (sin debug)\n";
    std::cout << "2. Ejecución completa (con debug)\n";
    std::cout << "3. Ejecución paso a paso (stepping)\n";
    std::cout << "Ingresa tu opción (1-3): ";
    std::cin >> choice;
    std::cin.ignore(); // Limpiar el buffer de entrada
    
    switch(choice) {
        case '1':
            debug = false;
            stepping = false;
            std::cout << "\n=== EJECUTANDO EN MODO COMPLETO (SIN DEBUG) ===\n";
            break;
        case '2':
            debug = true;
            stepping = false;
            std::cout << "\n=== EJECUTANDO EN MODO COMPLETO (CON DEBUG) ===\n";
            break;
        case '3':
            debug = true;
            stepping = true;
            std::cout << "\n=== EJECUTANDO EN MODO STEPPING ===\n";
            break;
        default:
            std::cout << "\nOpción inválida, usando modo completo sin debug.\n";
            debug = false;
            stepping = false;
            break;
    }

    MatC C;
    simulate_systolic(A, B, C, debug, stepping);

    // Mostrar resultado final
    std::cout << "\n=== RESULTADO FINAL ===\n";
    print_mat(C, 'C');

    // Comparar cada elemento con el resultado esperado
    for (int i = 0; i < N; ++i)
        for (int j = 0; j < N; ++j)
            assert(C[i][j] == C_expected[i][j]);

    std::cout << "Resultado Concuerda\n";
    return 0;
}