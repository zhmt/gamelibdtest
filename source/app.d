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
			
			ubyte[100] buf;
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
}

__gshared int n = 0;

void echoClient()
{
	import std.string;
	import gamelibd.util;

	spawn({
			long start = utcNow();
			int N = 10000000;
			int T = 1;

			ExceptionSafeFiber[] tasks;

			for(int ii=0; ii<T; ii++){
				auto t = spawn({
						import core.memory : GC;
						Ptr!Conn conn = connect("127.0.0.1",8881);
						ubyte[100] buf;
						char[100] buf2;
						auto str = sformat(buf2, "%s",299909);
						for(int i=0; i<N; i++)
						{
							conn.write((cast(ubyte*)str.ptr)[0..str.length]);
							conn.read(buf[0..str.length]);
							n+=1;
						}
						conn.close();
				
					});
				tasks~=t;
			}

			spawn({
					while(true)
					{
						ExceptionSafeFiber.sleep(1000);
						writeFlush(n,"\r\n");
					}
				});

			spawn({
					while(true)
					{
						ExceptionSafeFiber.sleep(1000);
						import core.memory : GC;
						//core.memory.GC.collect();
					}
				});

			spawn({
					ExceptionSafeFiber.sleep(1000*40);
					import std.c.process;
					//exit(0);
				});

			foreach(ExceptionSafeFiber t ; tasks)
				t.join();
			
			long end = utcNow();
			writeFlush(N/((end-start)/1000.0)*T);
			import std.c.process;
			exit(0);
		});
}


//,"-profile","-gc","-vgc"

//try telnet 127.0.0.1 8881

void main()
{
	//import core.memory : GC;
	//GC.disable();
	echoServer();
	echoClient();

	startEventLoop();
}
