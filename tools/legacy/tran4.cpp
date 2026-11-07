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
int fe=0;
void put(bool a){
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
void write(unsigned int a){
    unsigned int i=1;i<<=31;
    for(;i;i/=2)put(a&i);
}
void write(char a){
    for(int i=128;i;i/=2)put(a&i);
}
void write(string a){
    for(int i=0;i<a.length();i++)put(a[i]^48);
}
char b[5];
int read(){
    int a=0;
    fin.read(b,4);
    for(int i=0;i<4;i++)a=(a<<8)+((b[i]<0)?b[i]+256:b[i]);
    return a;
}
bool get(){
    if(pos==0){
        fin.read(buf,1);pos=128;
    }
    bool e=buf[0]&pos;pos>>=1;return e;
}
double hu(int a){
    return  a*3.1415926/180;
}
int uo[30];double dxx[30],dyy[30];
double pi=3.1415926535;
int main(){
    string bi,bo;
    int n;
    fout.open("sin.coe");
    din.open("data3.txt");
    
    fout<<";360*32"<<endl;
    fout<<"memory_initialization_radix=16;"<<endl;
    fout<<"memory_initialization_vector="<<endl;
    int R,r;double dx,dy;double bx=0,by=0;
    din>>R>>r;
    fe=4;
    for(int i=0;i<360;i++){
        unsigned short u=R*cos(hu(i)),v=R*sin(hu(i));
        unsigned int x=((unsigned int)u<<16)+v;
        write(x);
    //    cout<<i<<" "<<u<<" "<<v<<" "<<endl;
    }
    fout<<endl<<";";
    fe=8;
    fout.close();
    fout.open("road2.coe");
    fout2.open("music2.txt");
    fout<<";1k*64"<<endl;
    fout<<"memory_initialization_radix=16;"<<endl;
    fout<<"memory_initialization_vector="<<endl;
    unsigned int m,p,pp=0;
    din>>m;
    din>>dxx[0]>>dyy[0];
    cout<<"["<<m<<"]"<<endl;
    for(int i=0;i<20;i++){
        if(i<m)din>>p>>dxx[i+1]>>dyy[i+1];else p=0;
        uo[i+1]=p;
    //    cout<<p<<".."<<endl;
        write(pp);write(p);
    }uo[0]=0;
    din>>n;cout<<n<<endl;
    int ndev=0,pdev=180,ppdev=0;
    int sum=0;
    int noww=0;
    for(int i=0;i<1000-20;i++){
        if(i>=n){
            write((unsigned)0);
            write((unsigned)0);
            continue;
        }
        if(i==uo[noww]){cout<<endl<<endl;
            din>>bx>>by;
            dx=dxx[noww];
            dy=dyy[noww];
        }
        double aa,bb;
        int sa;
        unsigned int a,b,c,d;
        din>>c>>d;
        sum+=d;
        fout2<<sum<<endl;
        sa=ppdev;
     //   cout<<sa<<" "<<c<<" "<<d<<".."<<endl;
        aa=cos(sa*pi/180.0);
        bb=-sin(sa*pi/180.0);
        cout<<sa<<".."<<aa<<" "<<bb<<endl;
        if(i!=uo[noww]){
            bx=bx+aa*dx;
            by=by+bb*dy;
        }else noww++;
        int p=c?ndev:(360-ndev);
        p%=360;
        unsigned int pk=(pdev-p+360)%360;

        a=bx+0.5;b=by+0.5;
        ndev+=d;ndev%=360;
        
        cout<<i<<".."<<a<<" "<<b<<" "<<c<<" "<<d<<endl;//cout<<" "<<pk<<" "<<ndev<<" "<<pdev<<endl;
        //cout<<pdev<<"."<<ppdev<<" "<<sa<<endl;
        if(c)pdev-=180-d;
        else pdev+=180-d;
        ppdev=pdev+180;ppdev%=360;
        pdev=pdev+360;pdev%=360;
        
        write((a<<16)+b);
        write((c<<31)+(d<<16)+pk);
    }
    fin.close();
    fout<<endl<<";";
    fout.close();
}