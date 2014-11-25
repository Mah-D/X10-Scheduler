import x10.util.Random;
import x10.util.ArrayList;
import edu.ucla.cs.compilers.scheduler.Statement;
import edu.ucla.cs.compilers.scheduler.Scheduler;

public class Example1 {
	public static def print(x: Any) {Console.OUT.println(x);}
	
	
	
	private static def delay(time:Int){
		for(var i:Int=0; i<time; i++);
	}
	
	private static def delay(){
		if (!Scheduler.getVerbose())
			return;
		delay(1 << 26);
	}
	
	public static def main(Array[String]) {
		var x:Int = 4;
		var raceValue:Int = 5;
		// test1();
		// if (true)
			// return;
		
		
		val c = Clock.make(), c1 = Clock.make();
		Scheduler.addClock(c);
		Scheduler.addClock(c1);
		Scheduler.addPair(1,5);
		Scheduler.addPair(3,5);
		// Scheduler.addPair(2,4);
		// Scheduler.addPair(2,5);
		Scheduler.initScheduler();
		val seed = 8;
		
		finish{
			async clocked(c, c1){ /// here is the scheduler!
				Scheduler.schedule(seed);
			}
			
			async clocked(c){
				val thread = Scheduler.getThread(c);
				thread.start();
				
				thread.wait("raceValue = 6;", 1);
				raceValue = 6;
				print("1-2");
				delay();
				thread.wait("if(raceValue == 6) raceValue = 4;", 3);
				if (raceValue == 6) raceValue = 4;
				print("1-3");
				delay();
				thread.wait();
				print("1-4");
				delay();
				
				thread.exit();
			}
			async clocked(c1){
				val thread = Scheduler.getThread(c1);
				thread.start();
				
				thread.wait("if (x == 3) x = 4;", 4);
				if (x == 3) x = 4;
				print("2-2");
				delay();
				thread.wait("if (raceValue == 4) raceValue = 2;", 5);
				if (raceValue == 4) raceValue = 2;
				print("2-3");
				delay();
				thread.wait();
				print("2-4");
				delay();
				
				thread.exit();
			}
			c.drop();
			c1.drop();
		}
		Console.OUT.println(raceValue);
	}

}