#include<bits/stdc++.h>
#include<fstream>
#include<io.h>
#include<cstdio>
using namespace std;

ifstream fin,din,fin2;
ofstream fout,fout2;
char buf[1];int pos=0;
int pbuf[1];int posp=128;
char p[20]="0123456789ABCDEF";
int ze=0;
int fe=3;
void seter(bool a){
    if(a)pbuf[0]|=posp;
    posp>>=1;
    if(posp==0){
        fout<<p[pbuf[0]/16];
        fout<<p[pbuf[0]%16];
        ze++;
        if(ze==fe){
            fout<<" ";
            ze=0;
        }
        pbuf[0]=0;
        posp=128;
    }
}
void put(int a,int b){
    for(int i=1<<(b-1);i;i>>=1){
        seter(a&i);
    }
}
int op;
int trans(int a,int op){
    if(a==0)return 0;
    if(op==0){
        if(a<0)return -a;
        else return a+8;
    }else{
        if(a>=5)return a-5+1+8;
        else if(a>0)return a+3;
        else return -a-4;
    }
}
int main(){

    din.open("musicmodi.txt");
    fout.open("music.coe");
    fout<<";512*24"<<endl;
    fout<<"memory_initialization_radix=16;"<<endl;
    fout<<"memory_initialization_vector="<<endl;
    int a,b;
    int la=-10,lb=-10;
    op=1;
    int cnt=0;
    while(din>>a>>b){
        b=trans(b,op);
        if(b==lb){
            cnt++;
            if(cnt==10){
                fout<<endl;
                cnt=0;
            }
            put(a-5,20);
            put(0,4);
        }
        cnt++;
            if(cnt==10){
                fout<<endl;
                cnt=0;
            }
        put(a,20);
        put(b,4);
        la=a;lb=b;
    }
    fout<<endl<<";";
}