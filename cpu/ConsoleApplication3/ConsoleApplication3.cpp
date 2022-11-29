#include <iostream>
#include<vector>
#include<math.h>
#include<time.h>
#include<thread>

//#define PrintMatrix
class Solution {
public:
    void rotate(std::vector<std::vector<int>>& matrix)
    {
        //puts("rotation with ordinary method");
        int sz = matrix.size();
        int halfsz = ceil((double)sz / 2.0);
        int tempx = 0, tempy = 0;
        int temp = 0, tempPrev = 0;
        for (int i = 0; i < halfsz; i++)
        {
            for (int j = i; j < sz - 1 - i; j++)
            {
                tempx = i;
                tempy = j;

                for (int l = 0; l < 4; l++)
                {
                    temp = matrix[tempy][sz - 1 - tempx];

                    if (l > 0)
                        matrix[tempy][sz - 1 - tempx] = tempPrev;
                    else
                        matrix[tempy][sz - 1 - tempx] = matrix[tempx][tempy];

                    int oldTempx = tempx;
                    tempx = tempy;
                    tempy = sz - 1 - oldTempx;

                    tempPrev = temp;
                }
            }

        }
    }


    void rotate_thread(int istart, int iend, std::vector<std::vector<int>>& matrix)
    {

        int sz = matrix.size();
        int halfsz = ceil((double)sz / 2.0);
        int tempx = 0, tempy = 0;
        int temp = 0, tempPrev = 0;
        auto t1 = clock();
        for (int i = istart; i < iend; i++)
        {
            for (int j = i; j < sz - 1 - i; j++)
            {
                tempx = i;
                tempy = j;
                for (int l = 0; l < 4; l++)
                {
                    temp = matrix[tempy][sz - 1 - tempx];
                    if (l > 0)
                        matrix[tempy][sz - 1 - tempx] = tempPrev;
                    else
                        matrix[tempy][sz - 1 - tempx] = matrix[tempx][tempy];
                    int oldTempx = tempx;
                    tempx = tempy;
                    tempy = sz - 1 - oldTempx;
                    tempPrev = temp;
                }
            }
        }

        auto t2 = clock();
        printf("tid:%d %d(ms) ellapsed\n", std::this_thread::get_id(), t2 - t1);
        
    }

    //Currently with 2 thread only (Due to lacking comoputation power of personal 
    void rotate_multiThread(std::vector<std::vector<int>>& matrix)
    {
       // puts("rotation with multiThreadMethod");
        int sz = matrix.size();
        int halfsz = ceil((double)sz / 2.0);
        int tempx = 0, tempy = 0;
        int temp = 0, tempPrev = 0;
        std::vector<std::thread> thdLst;
        thdLst.push_back(std::thread(&Solution::rotate_thread, this, 0, halfsz / 2, std::ref(matrix)));
        thdLst.push_back(std::thread(&Solution::rotate_thread, this, halfsz / 2, halfsz, std::ref(matrix)));


        for (int i = 0; i < thdLst.size(); i++)
            thdLst[i].join();


    }

    void printMatrix(std::vector<std::vector<int>> matrix)
    {
        for (auto& x : matrix)
        {
            for (auto& y : x)
                std::cout << y << ",";
            std::cout << std::endl;
        }
    }

};


int main()
{
    Solution solution;

   
    int GivenMatrixSizeN = 15000;
    
    std::vector<std::vector<int>> matrix = std::vector<std::vector<int>>(GivenMatrixSizeN);
    int count = 0;
    for (int i = 0; i < GivenMatrixSizeN; i++)
        for (int j = 0; j < GivenMatrixSizeN; j++)        
            matrix[i].push_back(++count);

    auto t1 = clock();
    solution.rotate(matrix);
    //solution.rotate_multiThread(matrix);
    auto t2 = clock();

    std::cout << t2 - t1 <<"(ms) in total"<< std::endl;

#ifdef PrintMatrix
    solution.printMatrix(matrix);
#endif
    system("pause");
}


// 執行程式: Ctrl + F5 或 [偵錯] > [啟動但不偵錯] 功能表
// 偵錯程式: F5 或 [偵錯] > [啟動偵錯] 功能表

// 開始使用的提示: 
//   1. 使用 [方案總管] 視窗，新增/管理檔案
//   2. 使用 [Team Explorer] 視窗，連線到原始檔控制
//   3. 使用 [輸出] 視窗，參閱組建輸出與其他訊息
//   4. 使用 [錯誤清單] 視窗，檢視錯誤
//   5. 前往 [專案] > [新增項目]，建立新的程式碼檔案，或是前往 [專案] > [新增現有項目]，將現有程式碼檔案新增至專案
//   6. 之後要再次開啟此專案時，請前往 [檔案] > [開啟] > [專案]，然後選取 .sln 檔案
