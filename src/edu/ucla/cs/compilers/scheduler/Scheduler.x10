package edu.ucla.cs.compilers.scheduler;

import x10.util.*;
import x10.util.ArrayList;

public class Scheduler {
	static val cArr: ArrayList[Clock] = new ArrayList[Clock]();
	static val enabledThreads: ArrayList[MyThread] = new ArrayList[MyThread]();
	static val postponedThreads: ArrayList[MyThread] = new ArrayList[MyThread]();
	static val allThreads: ArrayList[MyThread] = new ArrayList[MyThread]();
	static val pairSets: ArrayList[Pair[Int, Int]] = new ArrayList[Pair[Int, Int]]();
	
	static class Verbose{
		public var value: Boolean = false;
	}
	private static val VERBOSE: Verbose = new Verbose();
	public static def setVerbose(verbose: Boolean) {VERBOSE.value = verbose;}
	public static def getVerbose(): Boolean{return VERBOSE.value;}
	public static def print(x: Any) {if (!VERBOSE.value){ return;}Console.OUT.println(x);}
	public static def printE(x: Any) {if (!VERBOSE.value){ return;}Console.ERR.println(x);}
	private static def delay(time:Int){
		for(var i:Int=0; i<time; i++);
	}
	
	private static def delay(){
		if (VERBOSE.value)
			delay(1 << 26);
	}
	public static def printArray[T](arr:ArrayList[T]){
		if (!VERBOSE.value)
			return;
		print("Array:");
		for(var i:Int =0; i<arr.size(); i++){
			print(arr(i));
		}
	}
	
	public static def initScheduler(){
		for(var i:Int =0; i<cArr.size(); i++){
			val c = cArr(i);
			val myThread = new MyThread(c);
			allThreads.add(myThread);
			enabledThreads.add(myThread);
		}
	}
	
	public static def addPair(first: Int, second: Int){
		val p = new Pair[Int, Int](first, second);
		pairSets.add(p);
	}
	
	
	public static def addClock(clock: Clock){
		print("this clock added:"+clock);
		cArr.add(clock);
	}
	
	public static def schedule(seed: Int){
		print("scheduling started!");
		val r:Random = new Random(seed);
		var count: Int = 0;
		while(enabledThreads.size() > 0)
		{
			// if (count++ == 20){
			// 	break;
			// }
			print("nextRound!");
			/*print("enabled!");
			printArray[MyThread](enabledThreads);
			print("postponed!");
			printArray[MyThread](postponedThreads);*/
			val enabledSubPost = enabledThreads.clone();
			enabledSubPost.removeAll(postponedThreads);
			val sizeOfEnabledSubPostThreads = enabledSubPost.size();
			// print(sizeOfEnabledSubPostThreads);
			if (sizeOfEnabledSubPostThreads != 0){
				val randomNumber = Math.abs(r.nextInt()) % sizeOfEnabledSubPostThreads;
				val t = enabledSubPost(randomNumber);
				if (t.isNextStatementInRaceSet()){
					print("this statement is in race set: "+t.nextStatement.string);
					val R = racing(t);
					if (R.size()!=0)/* actual race happened! */{
						Console.OUT.println("ERROR: actual race found with statement: "+ t.nextStatement);
						for(var i:Int = 0; i<R.size(); i++){
							Console.OUT.println("Race statment"+ (i+1)+": "+R.get(i).nextStatement);
						}
						if (r.nextBoolean()){
							t.execute();
						} else{
							postponedThreads.add(t);
							for(var i:Int=0; i<R.size();i++){
								val t1 = R(i);
								t1.execute();
								postponedThreads.remove(t1);
							}
						}
					} else /* wait for a race to happen */{
						print("this thread is added to postponed threads:"+t);
						postponedThreads.add(t);
					}
				}else{
					print("executing "+t);
					t.execute();
				}
			}
			else if (enabledThreads.size() != 0 && enabledThreads.size() == postponedThreads.size())/* remove a random element from postponed */{
				print("deadlock should be terminated!");
				val rand = Math.abs(r.nextInt()) % enabledThreads.size();
				val newT = postponedThreads(rand);
				postponedThreads.removeAt(rand);
				newT.execute();
			}
		}
		if (false){
			// TODO Deadlock
		}
	}
	/** this method return postponed threads which are in race with this thread!*/
	public static def racing(t: MyThread): ArrayList[MyThread]{
		val result:ArrayList[MyThread] = new ArrayList[MyThread]();
		for(var i:Int=0; i<postponedThreads.size(); i++){
			val t1 = postponedThreads(i);
			if(statementsHasRace(t, t1)){
				result.add(t1);
			}
		}
		return result;
	}
	
	public static def statementsHasRace(t1: MyThread, t2: MyThread): Boolean{
		val t1s = t1.nextStatement;
		val t2s = t2.nextStatement;
		//print("DEBUGGING statementsHasRace\n");
		//print("t1: "+t1s);
		//print("t2: "+t2s);
		if (t1s.readVars().contains(t2s.writeVars())){
			return true;
		}
		return t2s.readVars().contains(t1s.writeVars());
	}
	
	public static def getThread(clock: Clock):MyThread{
		for(var i:Int =0; i<allThreads.size(); i++){
			val t = allThreads(i);
			if (t.clock == clock)
				return t;
		}
		return null;
	}
	
	public static class MyThread{
		public static val allClocks:ArrayList[Clock] = new ArrayList[Clock]();
		public var isEnable: Boolean;
		public var isPostponed: Boolean;
		public var nextStatement: Statement;
		public var clock: Clock;
		public def this(clock: Clock){
			this.clock = clock;
			this.isEnable = true;
			this.isPostponed = false;
			nextStatement = Statement.createStatement("");
			allClocks.add(clock);
		}
		
		public def wait(){
			wait("", 0);
		}
		
		public def start(){ // this method must be called by executing threads!
			printE("start started "+this);
			delay();
			clock.advance(); // for bocking itself till the turn arrives!
			printE("start finished "+this);
			delay();
		}
		
		public def wait(nextStatement: String, line:Int){ // this method must be called by executing threads!
			this.nextStatement = Statement.createStatement(nextStatement, line);
			printE("wait started "+this);
			delay();
			clock.advance(); // for notifying scheduler
			printE("wait promoted "+this);
			delay();
			clock.advance(); // for bocking itself till the turn arrives!
			printE("wait finished "+this);
			delay();
		}
		
		public def execute(){ // this method must be called by scheduler thread!
			printE("execute started "+this);
			delay();
			clock.advance(); // for notifying turned thread!
			printE("execute promoted "+this);
			delay();
			clock.advance(); // for blocking scheduler till the thread finishes its work!
			printE("execute finished "+this);
			delay();
		}
		
		public def exit(){ // this method must be called by owner thread!
			this.isEnable = false;
			enabledThreads.remove(this);
			clock.drop();
		}
		
		public def isNextStatementInRaceSet(){
			print("nextS "+nextStatement);
			print("pairSets.size "+pairSets.size());
			for(var i:Int=0; i<pairSets.size(); i++){
				val p = pairSets.get(i);
				if (p.first == nextStatement.line || p.second == nextStatement.line)
					return true;
			}
			return false;
		}
		
		public def toString(): String{
			return "t with clock: "+allClocks.indexOf(clock);
		}
	}
}
