package edu.ucla.cs.compilers.scheduler;

import x10.util.*;

public abstract class Statement extends Term{
	
	public var line: Int;
	
	public def this(string: String){
		super(string);
		line = -1;
	}
	public abstract def writeVars(): Variable;
	public abstract def readVars(): ArrayList[Variable];
	
	public static def createStatement(string: String, line: Int): Statement{
		val result = createStatement(string);
		result.line = line;
		return result;
	}
	
	public static def createStatement(string: String): Statement{
		if (string.indexOf("if") == 0 && !string(2).isLetterOrDigit())
			return new IfStatement(string);
		else if (string.indexOf("=") != -1){
			return new AssignmentStatement(string);
		}
		return new NullStatement();
	}

	public def toString(): String{
		return "line["+line+"]: "+string;
	}
}

class NullStatement extends Statement{
	public def this(){
		super("");
	}
	public def writeVars(): Variable{
		return null;
	}
	public def readVars(): ArrayList[Variable]{
		return new ArrayList[Variable]();
	}
}

abstract class Term{
	protected var string: String;
	public def this(string: String){
		this.string = string;
	}
}

class Expression extends Term{
	
	private var vars: ArrayList[Variable];
	public def this(string: String){
		super(string);
		// Scheduler.print("wants to make Expression for: "+string);
		this.string = string;
		vars = new ArrayList[Variable]();
		var isVar:Boolean = false;
		var varTillNow:String = "";
		for(var i:Int=0; i<string.length(); i++){
			val c = string(i);
			if (isVar){
				if(c.isLetterOrDigit()){
					varTillNow += c;
				}else{
					vars.add(new Variable(varTillNow));
					varTillNow = "";
					isVar = false;
				}
			} else {
				if(c.isLetter()){
					varTillNow += c;
					isVar = true;
				}
			}
		}
		if (varTillNow.length() != 0)
			vars.add(new Variable(varTillNow));
	}
	public def readVars(): ArrayList[Variable]{
		var result:ArrayList[Variable] = new ArrayList[Variable]();
		for(var i:Int=0; i<vars.size(); i++)
			result.add(vars(i));
		return result;
	}
}

class Variable extends Term{
	public def this(string: String){
		super(string);
	}
	
	public def equals(that: Any): Boolean{
		val v: Variable = that as Variable;
		return v.string.equals(this.string);
	}
}

class AssignmentStatement extends Statement{
	var leftVar: Variable;
	var exp: Expression;
	public def this(string:String) {
	    super(string);
	    val i = string.indexOf("=");
	    leftVar = new Variable(string.substring(0, i).trim());
	    exp = new Expression(string.substring(i+1).trim());
	}
	public def writeVars(): Variable{
		return leftVar;
	}
	public def readVars(): ArrayList[Variable]{
		return exp.readVars();
	}
}

class IfStatement extends Statement {
	var condition: Expression;
	var thenStatement: Statement;
	
	public def this(string:String) {
		super(string);
		var depth:Int = 1;
		val start = string.indexOf("(")+1; 
		var i:Int = start;
		for (; i<string.length(); i++){
			val c = string(i);
			if (c == '(')
				depth++;
			else if (c == ')')
				depth--;
			if (depth == 0)
				break;
		}
		condition = new Expression(string.substring(start, i));
		thenStatement = Statement.createStatement(string.substring(i+1));
	}
	public def writeVars(): Variable{
		return thenStatement.writeVars();
	}
	public def readVars(): ArrayList[Variable]{
		val result: ArrayList[Variable] = new ArrayList[Variable]();
		result.addAll(condition.readVars());
		result.addAll(thenStatement.readVars());
		return result;
	}
}

/*class StatementTester {
	private static def test1(){
		val s = Statement.createStatement("if    (x==y)      x=z+y");
		val ifs:IfStatement = s as IfStatement;
		Scheduler.printArray[String](ifs.readVars());
	}
	
	private static def test2(){
		val s = Statement.createStatement("x=z+y-  1+    zzzz");
		val asss:AssignmentStatement = s as AssignmentStatement;
		Scheduler.printArray[String](asss.readVars());
	}
}*/