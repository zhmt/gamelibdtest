import std.stdio;

import gamelibd.net.conn;

import gamelibd.util;

void echoServerWithProxy()
{
	Acceptor acc = new Acceptor();
	acc.listen("0.0.0.0",8880,100);
	acc.accept((Ptr!Conn c){
			
			Ptr!Conn rmt = connect("127.0.0.1",8881);
			scope (exit) rmt.free();
			
			auto t1 = spawn((){
					scope(exit) { 
						c.close();
						rmt.close();
					}
					scope(exit) writeFlush("exit1");
					ubyte[5] buf;
					while(true)
					{
						int n = c.readSome(buf);
						if(n<=0){
							writeFlush("break");
							break;
						}
						rmt.write(buf[0..n]);
					}
				});
			
			auto t2 = spawn((){
					scope(exit) { 
						c.close();
						rmt.close();
					}
					
					scope(exit) writeFlush("exit2");
					ubyte[5] buf;
					while(true)
					{
						int n = rmt.readSome(buf);
						if(n<=0){
							break;
						}
						c.write(buf[0..n]);
					}
				});
			
			
			t1.join();
			t2.join();
			
			writeFlush("close forwarder sock");
		});
	
	Acceptor acc2 = new Acceptor();
	acc2.listen("0.0.0.0",8881,100);
	acc2.accept((Ptr!Conn c){
			scope(exit) c.close();
			
			ubyte[5] buf;
			while(true)
			{
				int n = c.readSome(buf);
				if(n<=0){
					break;
				}
				c.write(buf[0..n]);
			}
			writeFlush("close server sock");
		});
	
	startEventLoop();
}


void echoServer()
{
	Acceptor acc2 = new Acceptor();
	acc2.listen("0.0.0.0",8881,100);
	acc2.accept((Ptr!Conn c){
			scope(exit) c.close();
			
			ubyte[5] buf;
			while(true)
			{
				int n = c.readSome(buf);
				if(n<=0){
					break;
				}
				c.write(buf[0..n]);
			}
			writeFlush("close server sock");
		});
	
	startEventLoop();
}

//try telnet 127.0.0.1 8881

void main()
{
	echoServer();
}
