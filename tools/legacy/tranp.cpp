#include<bits/stdc++.h>
#include<fstream>
#include<io.h>
#include<cstdio>
using namespace std;

ifstream fin,din,fin2;
ofstream fout;
int p[10][5]={
    {7,5,5,5,7},
    {1,1,1,1,1},
    {7,1,7,4,7},
    {7,1,7,1,7},
    {5,5,7,1,1},
    {7,4,7,1,7},
    {7,4,7,5,7},
    {7,1,1,1,1},
    {7,5,7,5,7},
    {7,5,7,1,7}
};
int le[5]={2,2,2,2,2};
int lp[3]={2,3,2};
string zero="000 ";
string have="00f ";
int main(){
    string bi,bo;
    int n;
    fout.open("putd.coe");
    fout<<"1k*12"<<endl;
    fout<<"memory_initialization_radix=16;"<<endl;
    fout<<"memory_initialization_vector="<<endl;
    int x=9,y=10;
    for(int i=0;i<=9;i++){
        for(int l=0;l<5;l++){
            for(int o=0;o<2;o++){
                fout<<zero;
                int z=4;
                for(int j=0;j<3;j++){
                    if(z&p[i][l])
                        for(int jj=0;jj<lp[j];jj++)fout<<have;
                    else 
                        for(int jj=0;jj<lp[j];jj++)fout<<zero;
                    z>>=1;
                }
                fout<<zero<<endl;
            }
        }
    }
    for(int i=9*10*10;i<1024;i++)fout<<zero;
    fout<<endl<<";";

    fout.close();
}