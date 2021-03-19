/**
 * GMCR (c) YellowAfterlife, 2017+
 * Not part of MIT-licensed source code.
 */
(function(){
function sfjs_extend(cls, sup, fields){
	var proto;
	if(sup){
		function base(){}
		base.prototype=sup.prototype;
		var proto=new base();
		for(var name in fields)proto[name]=fields[name];
		if(fields.toString!==Object.prototype.toString)proto.toString = fields.toString;
		
	} else proto = fields;
	cls.prototype=proto;
}
function sfjs_toString(){
	return js_Boot___string_rec(this,"");
}
function EReg(r,opt){
	this.r=new RegExp(r,opt.split("u").join(""));
}
EReg.prototype={
	match:function(s){
		if(this.r.global)this.r.lastIndex=0;
		this.r.m=this.r.exec(s);
		this.r.s=s;
		return this.r.m!=null;
	},
	matched:function(n){
		if(this.r.m!=null&&n>=0&&n<this.r.m.length){
			return this.r.m[n];
		}else throw new js__Boot_HaxeError("EReg::matched");
	},
	matchedPos:function(){
		if(this.r.m==null)throw new js__Boot_HaxeError("No string matched");
		return {pos:this.r.m.index,len:this.r.m[0].length};
	},
	matchSub:function(s,pos,len){
		if(len==null)len=-1;
		if(this.r.global){
			this.r.lastIndex=pos;
			this.r.m=this.r.exec((len<0)?s:HxOverrides_substr(s,0,pos+len));
			var b=this.r.m!=null;
			if(b)this.r.s=s;
			return b;
		}else {
			var b1=this.match((len<0)?HxOverrides_substr(s,pos,null):HxOverrides_substr(s,pos,len));
			if(b1){
				this.r.s=s;
				this.r.m.index+=pos;
			}
			return b1;
		}
	},
	map:function(s,f){
		var offset=0;
		var buf_b="";
		while(true){
			if(offset>=s.length){
				break;
			}else if(!this.matchSub(s,offset)){
				buf_b+=Std_string(HxOverrides_substr(s,offset,null));
				break;
			}
			var p=this.matchedPos();
			buf_b+=Std_string(HxOverrides_substr(s,offset,p.pos-offset));
			buf_b+=Std_string(f(this));
			if(p.len==0){
				buf_b+=Std_string(HxOverrides_substr(s,p.pos,1));
				offset=p.pos+1;
			}else offset=p.pos+p.len;
			if(!this.r.global)break;
		}
		if(!this.r.global&&offset>0&&offset<s.length)buf_b+=Std_string(HxOverrides_substr(s,offset,null));
		return buf_b;
	}
}
function GmlBuilder(src){
	this.errorText=null;
	this.macroNodes=[];
	this.macroNames=[];
	this.enums=[];
	this.scripts=[];
	this.offset=0;
	this.source=src;
	this.tokens=GmlParser_run(src);
	if(this.tokens!=null){
		this.length=this.tokens.length;
		this.buildLoop(src.main);
	}else {
		this.errorText=GmlParser_errorText;
		this.errorPos=GmlParser_errorPos;
	}
}
GmlBuilder.prototype={
	errorAt:function(text,pos){
		this.errorText=pos.toString()+": "+text;
		this.errorPos=pos;
		return true;
	},
	error:function(text,tk){
		return this.errorAt(text,tk[2]);
	},
	expectNode:function(text,node){
		return this.errorAt("Expected "+text+", got "+node[0],node[2]);
	},
	buildOps:function(firstPos,firstOp){
		this.offset+=1;
		var nodes=[];
		nodes.push(this.outNode);
		var ops=[];
		ops.push(firstOp);
		var locs=[];
		locs.push(firstPos);
		var proc=true;
		var i;
		while(proc&&this.offset<this.length){
			if(this.buildExpr(1))return true;
			nodes.push(this.outNode);
			if(this.offset<this.length){
				var _g=this.tokens[this.offset];
				switch(_g[1]){
					case 19:
						if(_g[3]==-1){
							this.offset+=1;
							locs.push(_g[2]);
							ops.push(64);
						}else proc=false;
						break;
					case 18:
						this.offset+=1;
						locs.push(_g[2]);
						ops.push(_g[3]);
						break;
					default:proc=false;
				}
			}
		}
		var pmin=7;
		var pmax=0;
		var n=ops.length;
		for(i=0;i<n;++i){
			var pcur=ast__GmlOp_GmlOp_Impl__getPriority(ops[i]);
			if(pcur<pmin)pmin=pcur;
			if(pcur>pmax)pmax=pcur;
		}
		while(pmin<=pmax){
			for(i=0;i<n;++i)if(ast__GmlOp_GmlOp_Impl__getPriority(ops[i])==pmin){
				nodes[i]=ast_GmlNodeDef_BinOp(locs[i],ops[i],nodes[i],nodes[i+1]);
				nodes.splice(i+1,1);
				ops.splice(i,1);
				locs.splice(i,1);
				--n;
				--i;
			}
			++pmin;
		}
		this.outNode=nodes[0];
		return false;
	},
	buildArgs:function(pos,sqb){
		var args=[];
		var proc=true;
		var seenComma=true;
		var func=this.outNode;
		while(proc&&this.offset<this.length){
			var tk=this.tokens[this.offset];
			switch(tk[1]){
				case 21:
					if(sqb){
						return this.error("Unexpected `)`",tk);
					}else {
						proc=false;
						this.offset+=1;
					}
					break;
				case 4:
					if(seenComma){
						return this.error("Unexpected comma",tk);
					}else {
						seenComma=true;
						this.offset+=1;
					}
					break;
				default:
					if(seenComma){
						seenComma=false;
						if(this.buildExpr(0))return true;
						args.push(this.outNode);
					}else return this.error("Expected a comma or closing token., got "+tk[0],tk);
			}
		}
		if(proc)return this.errorAt("Unclosed list",pos);
		if(sqb){
			this.outNode=ast_GmlNodeDef_ArrayDecl(pos,args);
		}else this.outNode=ast_GmlNodeDef_Call(pos,func,args);
		return false;
	},
	buildExpr:function(flags){
		if(this.offset>=this.length)return this.errorAt("Expected an expression",this.source.eof);
		var proc, sep, i, n, s, tk;
		var tk0=this.tokens[this.offset++];
		var node, node2, nodes;
		switch(tk0[1]){
			case 18:
				switch(tk0[3]){
					case 16:
						var d9=tk0[2];
						if(this.buildExpr(1))return true;
						break;
					case 17:
						var d10=tk0[2];
						if(this.buildExpr(1))return true;
						var _g5=this.outNode;
						if(_g5[1]==1){
							this.outNode=ast_GmlNodeDef_Number(d10, -_g5[3],null);
						}else this.outNode=ast_GmlNodeDef_UnOp(d10,this.outNode,0);
						break;
					default:if((flags&4)!=0){
						return this.error("Expected a statement, got "+tk0[0],tk0);
					}else return this.error("Expected a value, got "+tk0[0],tk0);
				}
				break;
			case 9:
				switch(tk0[3]){
					case 0:
						var d=tk0[2];
						if(this.offset>=this.length){
							this.outNode=ast_GmlNodeDef_GlobalRef(d);
						}else if(this.tokens[this.offset][1]==5){
							tk=this.tokens[this.offset++];
							if(this.offset>=this.length){
								return this.error("Expected a field name, got "+tk[0],tk);
							}else {
								var _g1=this.tokens[this.offset];
								if(_g1[1]==10){
									this.offset+=1;
									this.outNode=ast_GmlNodeDef_Global(_g1[2],_g1[3]);
								}else {
									var tk1=this.tokens[this.offset];
									return this.error("Expected a field name, got "+tk1[0],tk1);
								}
							}
						}else this.outNode=ast_GmlNodeDef_GlobalRef(d);
						break;
					case 24:
						if(this.offset>=this.length){
							return this.errorAt("Expected an opening square bracket",this.source.eof);
						}else if(this.tokens[this.offset][1]==22){
							this.offset+=1;
						}else return this.error("Expected an opening square bracket",this.tokens[this.offset]);
						if(this.buildExpr(0))return true;
						if(this.offset>=this.length){
							return this.errorAt("Expected a closing square bracket",this.source.eof);
						}else if(this.tokens[this.offset][1]==23){
							this.offset+=1;
						}else return this.error("Expected a closing square bracket",this.tokens[this.offset]);
						this.outNode=ast_GmlNodeDef_ArgIndex(tk0[2],this.outNode);
						break;
					case 25:this.outNode=ast_GmlNodeDef_ArgCount(tk0[2]);break;
					default:if((flags&4)!=0){
						return this.error("Expected a statement, got "+tk0[0],tk0);
					}else return this.error("Expected a value, got "+tk0[0],tk0);
				}
				break;
			case 12:this.outNode=ast_GmlNodeDef_Undefined(tk0[2]);break;
			case 13:this.outNode=ast_GmlNodeDef_Number(tk0[2],tk0[3],tk0[4]);break;
			case 14:this.outNode=ast_GmlNodeDef_CString(tk0[2],tk0[3]);break;
			case 22:
				proc=true;
				sep=true;
				nodes=[];
				while(proc&&this.offset<this.length){
					switch(this.tokens[this.offset][1]){
						case 23:
							this.offset+=1;
							proc=false;
							break;
						case 4:
							if(sep){
								var tk2=this.tokens[this.offset];
								return this.error("Expected a value or closing bracket, got "+tk2[0],tk2);
							}else {
								this.offset+=1;
								sep=true;
							}
							break;
						default:
							if(this.buildExpr(0))return true;
							nodes.push(this.outNode);
							sep=false;
					}
				}
				this.outNode=ast_GmlNodeDef_ArrayDecl(tk0[2],nodes);
				break;
			case 10:
				var s2=tk0[3];
				switch(s2){
					case "self":this.outNode=ast_GmlNodeDef_Self(tk0[2]);break;
					case "other":this.outNode=ast_GmlNodeDef_Other(tk0[2]);break;
					default:
						if(data_GmlAPI_assetIndex[s2]!=null){
							i=data_GmlAPI_assetIndex[s2];
							this.outNode=ast_GmlNodeDef_Number(tk0[2],i,null);
						}else this.outNode=ast_GmlNodeDef_Ident(tk0[2],s2);
				}
				break;
			case 26:this.outNode=ast_GmlNodeDef_ArgConst(tk0[2],tk0[3]);break;
			case 15:
				if(this.buildExpr(1))return true;
				var _g4=this.outNode;
				if(_g4[1]==1){
					var f1=_g4[3];
					switch(tk0[3]){
						case 2:f1=~(f1|0);break;
						case 0:f1= -f1;break;
						case 1:f1=(f1>0.5)?0:1;break;
					}
					this.outNode=ast_GmlNodeDef_Number(tk0[2],f1,null);
				}else this.outNode=ast_GmlNodeDef_UnOp(tk0[2],this.outNode,tk0[3]);
				break;
			case 17:
				if(this.buildExpr(1))return true;
				this.outNode=ast_GmlNodeDef_Prefix(tk0[2],this.outNode,tk0[3]);
				break;
			case 20:
				if(this.buildExpr(0))return true;
				if(this.offset>=this.length)return this.error("Unclosed parenthesis",tk0);
				if(this.offset>=this.length){
					return this.errorAt("Expected a closing parenthesis",this.source.eof);
				}else if(this.tokens[this.offset][1]==21){
					this.offset+=1;
				}else return this.error("Expected a closing parenthesis",this.tokens[this.offset]);
				break;
			case 24:
				var keys=[];
				nodes=[];
				proc=true;
				if(this.tokens[this.offset][1]==25){
					this.offset+=1;
				}else while(proc&&this.offset<this.length){
					var _g11=this.tokens[this.offset];
					switch(_g11[1]){
						case 14:
							s=_g11[3];
							keys.push(s);
							this.offset+=1;
							if(this.offset>=this.length){
								return this.errorAt("Expected a `:` in object declaration",this.source.eof);
							}else if(this.tokens[this.offset][1]==6){
								this.offset+=1;
							}else return this.error("Expected a `:` in object declaration",this.tokens[this.offset]);
							if(this.buildExpr(0))return true;
							nodes.push(this.outNode);
							switch(this.tokens[this.offset][1]){
								case 4:
									this.offset+=1;
									if(this.tokens[this.offset][1]==25){
										this.offset+=1;
										proc=false;
									}
									break;
								case 25:
									this.offset+=1;
									proc=false;
									break;
								default:
									var tk4=this.tokens[this.offset];
									return this.error("Expected a `,` or a `}` in object declaration, got "+tk4[0],tk4);
							}
							break;
						case 10:
							s=_g11[3];
							keys.push(s);
							this.offset+=1;
							if(this.offset>=this.length){
								return this.errorAt("Expected a `:` in object declaration",this.source.eof);
							}else if(this.tokens[this.offset][1]==6){
								this.offset+=1;
							}else return this.error("Expected a `:` in object declaration",this.tokens[this.offset]);
							if(this.buildExpr(0))return true;
							nodes.push(this.outNode);
							switch(this.tokens[this.offset][1]){
								case 4:
									this.offset+=1;
									if(this.tokens[this.offset][1]==25){
										this.offset+=1;
										proc=false;
									}
									break;
								case 25:
									this.offset+=1;
									proc=false;
									break;
								default:
									var tk3=this.tokens[this.offset];
									return this.error("Expected a `,` or a `}` in object declaration, got "+tk3[0],tk3);
							}
							break;
						default:
							var tk5=this.tokens[this.offset];
							return this.error("Expected a key-value pair or a `}` in object declaration, got "+tk5[0],tk5);
					}
				}
				this.outNode=ast_GmlNodeDef_ObjectDecl(tk0[2],keys,nodes);
				break;
			case 28:
				if(this.buildExpr(flags))return true;
				this.outNode=ast_GmlNodeDef_CommentLineSep(tk0[2],tk0[3],this.outNode);
				break;
			case 27:
				if(this.buildExpr(flags))return true;
				this.outNode=ast_GmlNodeDef_CommentLinePre(tk0[2],tk0[3],this.outNode);
				break;
			case 29:
				if(this.buildExpr(flags))return true;
				this.outNode=ast_GmlNodeDef_CommentBlockPre(tk0[2],tk0[3],this.outNode,tk0[4]);
				break;
			case 0:if((flags&4)!=0){
				return this.error("Expected a statement, got a header (did you miss a closing bracket?)",tk0);
			}else return this.error("Expected an expression, got a header (did you miss a closing parenthesis?)",tk0);
			default:if((flags&4)!=0){
				return this.error("Expected a statement, got "+tk0[0],tk0);
			}else return this.error("Expected a value, got "+tk0[0],tk0);
		}
		proc=true;
		while(proc&&this.offset<this.length){
			tk=this.tokens[this.offset];
			switch(tk[1]){
				case 19:
					if(tk[3]==-1){
						var p1=tk[2];
						if((flags&1)==0){
							if(this.buildOps(p1,64))return true;
							flags|=2;
						}else proc=false;
					}else proc=false;
					break;
				case 15:
					if(tk[3]==1){
						var d20=tk[2];
						if((flags&2)==0){
							this.offset+=1;
							if(this.tokens[this.offset][1]==16){
								node=this.outNode;
								this.offset+=1;
								if(this.buildExpr(1))return true;
								this.outNode=ast_GmlNodeDef_In(d20,node,this.outNode,true);
							}else this.offset-=1;
						}
					}else proc=false;
					break;
				case 17:
					if((flags&2)==0){
						this.offset+=1;
						this.outNode=ast_GmlNodeDef_Postfix(tk[2],this.outNode,tk[3]);
						flags|=2;
					}else if(tk[3]){
						return this.errorAt("Unexpected `++`",tk[2]);
					}else return this.errorAt("Unexpected `--`",tk[2]);
					break;
				case 5:
					if((flags&2)==0){
						this.offset+=1;
						var _g9=this.tokens[this.offset];
						if(_g9[1]==10){
							s=_g9[3];
							this.offset+=1;
							this.outNode=ast_GmlNodeDef_Field(tk[2],this.outNode,s);
						}else return this.error("Expected a field name",this.tokens[this.offset]);
					}else return this.error("Unexpected period",this.tokens[this.offset]);
					break;
				case 20:
					if((flags&2)==0){
						this.offset+=1;
						if(this.buildArgs(tk[2],false))return true;
					}else return this.errorAt("Unexpected `(`",tk[2]);
					break;
				case 22:
					var d24=tk[2];
					if((flags&2)==0){
						this.offset+=1;
						if(this.offset>=this.length)return this.errorAt("Expected an index",this.source.eof);
						node=this.outNode;
						var _g19=this.tokens[this.offset];
						switch(_g19[1]){
							case 18:
								if(_g19[3]==48){
									this.offset+=1;
									if(this.buildExpr(0))return true;
									if(this.offset>=this.length){
										return this.errorAt("Expected a closing bracket",this.source.eof);
									}else if(this.tokens[this.offset][1]==23){
										this.offset+=1;
									}else return this.error("Expected a closing bracket",this.tokens[this.offset]);
									this.outNode=ast_GmlNodeDef_DsList(d24,node,this.outNode);
								}else proc=false;
								break;
							case 7:
								this.offset+=1;
								if(this.buildExpr(0))return true;
								if(this.offset>=this.length){
									return this.errorAt("Expected a closing bracket",this.source.eof);
								}else if(this.tokens[this.offset][1]==23){
									this.offset+=1;
								}else return this.error("Expected a closing bracket",this.tokens[this.offset]);
								this.outNode=ast_GmlNodeDef_DsMap(d24,node,this.outNode);
								break;
							case 2:
								this.offset+=1;
								if(this.buildExpr(0))return true;
								node2=this.outNode;
								if(this.offset>=this.length){
									return this.errorAt("Expected a comma",this.source.eof);
								}else if(this.tokens[this.offset][1]==4){
									this.offset+=1;
								}else return this.error("Expected a comma",this.tokens[this.offset]);
								if(this.buildExpr(0))return true;
								if(this.offset>=this.length){
									return this.errorAt("Expected a closing bracket",this.source.eof);
								}else if(this.tokens[this.offset][1]==23){
									this.offset+=1;
								}else return this.error("Expected a closing bracket",this.tokens[this.offset]);
								this.outNode=ast_GmlNodeDef_DsGrid(d24,node,node2,this.outNode);
								break;
							case 8:
								this.offset+=1;
								if(this.buildExpr(0))return true;
								if(this.offset>=this.length)return this.errorAt("Expected comma or a closing bracket",this.source.eof);
								switch(this.tokens[this.offset][1]){
									case 4:
										this.offset+=1;
										node2=this.outNode;
										if(this.buildExpr(0))return true;
										if(this.offset>=this.length){
											return this.errorAt("Expected a closing bracket",this.source.eof);
										}else if(this.tokens[this.offset][1]==23){
											this.offset+=1;
										}else return this.error("Expected a closing bracket",this.tokens[this.offset]);
										this.outNode=ast_GmlNodeDef_RawId2d(d24,node,node2,this.outNode);
										break;
									case 23:
										this.offset+=1;
										this.outNode=ast_GmlNodeDef_RawId(d24,node,this.outNode);
										break;
									default:
										var tk6=this.tokens[this.offset];
										this.error("Expected comma or a closing bracket, got "+tk6[0],tk6);
								}
								break;
							default:proc=false;
						}
						if(!proc){
							proc=true;
							if(this.buildExpr(0))return true;
							if(this.offset>=this.length)return this.errorAt("Expected comma or a closing bracket",this.source.eof);
							switch(this.tokens[this.offset][1]){
								case 4:
									this.offset+=1;
									node2=this.outNode;
									if(this.buildExpr(0))return true;
									if(this.offset>=this.length){
										return this.errorAt("Expected a closing bracket",this.source.eof);
									}else if(this.tokens[this.offset][1]==23){
										this.offset+=1;
									}else return this.error("Expected a closing bracket",this.tokens[this.offset]);
									this.outNode=ast_GmlNodeDef_Index2d(d24,node,node2,this.outNode);
									break;
								case 23:
									this.offset+=1;
									this.outNode=ast_GmlNodeDef_Index(d24,node,this.outNode);
									break;
								default:
									var tk7=this.tokens[this.offset];
									this.error("Expected comma or a closing bracket, got "+tk7[0],tk7);
							}
						}
					}else return this.errorAt("Unexpected `[`",d24);
					break;
				case 16:
					if((flags&2)==0){
						node=this.outNode;
						this.offset+=1;
						if(this.buildExpr(1))return true;
						this.outNode=ast_GmlNodeDef_In(tk[2],node,this.outNode,false);
					}
					break;
				case 18:
					if((flags&1)==0){
						if(this.buildOps(tk[2],tk[3]))return true;
						flags|=2;
					}else proc=false;
					break;
				case 7:
					if((flags&1)==0){
						this.offset+=1;
						node=this.outNode;
						if(this.buildExpr(0))return true;
						node2=this.outNode;
						if(this.offset>=this.length){
							return this.errorAt("Expected an else-colon",this.source.eof);
						}else if(this.tokens[this.offset][1]==6){
							this.offset+=1;
						}else return this.error("Expected an else-colon",this.tokens[this.offset]);
						if(this.buildExpr(0))return true;
						this.outNode=ast_GmlNodeDef_Ternary(tk[2],node,node2,this.outNode);
					}else proc=false;
					break;
				case 27:
					this.offset+=1;
					this.outNode=ast_GmlNodeDef_CommentLinePost(tk[2],this.outNode,tk[3]);
					break;
				case 28:this.offset+=1;break;
				case 29:
					this.offset+=1;
					this.outNode=ast_GmlNodeDef_CommentBlockPost(tk[2],this.outNode,tk[3],tk[4]);
					break;
				default:proc=false;
			}
		}
		return false;
	},
	buildLine:function(){
		if(this.offset>=this.length)return this.errorAt("Expected a statement",this.source.eof);
		var tk=this.tokens[this.offset++];
		var tk2, proc, sep, x, x1, x2, nodes, i, s, d;
		var unknown=false;
		switch(tk[1]){
			case 9:
				switch(tk[3]){
					case 1:
						d=tk[2];
						this.outNode=ast_GmlNodeDef_Block(d,[]);
						while(this.offset<this.length){
							tk2=this.tokens[this.offset++];
							if(tk2[1]==10){
								d=tk2[2];
								s=tk2[3];
								i=this.macroNames.length;
								this.macroNames[i]=s;
								this.macroNodes[i]=ast_GmlNodeDef_Global(d,s);
								if(this.tokens[this.offset][1]==4){
									this.offset+=1;
									continue;
								}
							}else return this.error("Expected a global variable name.",tk2);
							break;
						}
						break;
					case 2:
						var d2=tk[2];
						nodes=[];
						proc=true;
						while(proc&&this.offset<this.length){
							tk2=this.tokens[this.offset++];
							if(tk2[1]==10){
								if(this.offset>=this.length)return this.errorAt("Expected a variable value",this.source.eof);
								tk=this.tokens[this.offset];
								if(tk[1]==19){
									if(tk[3]==-1){
										this.offset+=1;
										if(this.buildExpr(0))return true;
									}else this.outNode=null;
								}else this.outNode=null;
								nodes.push(ast_GmlNodeDef_VarDecl(tk2[2],tk2[3],this.outNode));
								if(this.offset<this.length)switch(this.tokens[this.offset][1]){
									case 4:this.offset+=1;break;
									case 3:
										this.offset+=1;
										proc=false;
										break;
									default:proc=false;
								}
							}else return this.error("Expected a variable name, got "+tk2[0],tk2);
						}
						if(nodes.length!=1){
							this.outNode=ast_GmlNodeDef_Block(d2,nodes);
						}else this.outNode=nodes[0];
						break;
					case 3:
						var e;
						var _g3=this.tokens[this.offset];
						if(_g3[1]==10){
							var s2=_g3[3];
							var d5=_g3[2];
							this.offset+=1;
							e=new ast_GmlEnum(s2,d5);
						}else return this.error("Expected an enum name",this.tokens[this.offset]);
						if(this.offset>=this.length){
							return this.errorAt("Expected enum block",this.source.eof);
						}else if(this.tokens[this.offset][1]==24){
							this.offset+=1;
						}else return this.error("Expected enum block",this.tokens[this.offset]);
						proc=true;
						sep=true;
						while(this.offset<this.length&&proc){
							var _g12=this.tokens[this.offset];
							switch(_g12[1]){
								case 25:
									this.offset+=1;
									proc=false;
									break;
								case 4:
									if(sep){
										return this.error("Unexpected comma",this.tokens[this.offset]);
									}else {
										this.offset+=1;
										sep=true;
									}
									break;
								case 10:
									if(sep){
										this.offset+=1;
										var _g13=this.tokens[this.offset];
										if(_g13[1]==19){
											if(_g13[3]==-1){
												this.offset+=1;
												if(this.buildExpr(0))return true;
											}else this.outNode=null;
										}else this.outNode=null;
										var ec=new ast_GmlEnumCtr(_g12[3],_g12[2],this.outNode);
										e.ctrList.push(ec);
										e.ctrMap[ec.name]=ec;
										sep=false;
									}else {
										var tk1=this.tokens[this.offset];
										return this.error("Expected a comma or a closing bracket, got "+tk1[0],tk1);
									}
									break;
								default:
									var tk3=this.tokens[this.offset];
									return this.error("Expected a comma, enum entry, or closing bracket, got "+tk3[0],tk3);
							}
						}
						if(proc)return this.error("Unclosed enum-block",tk);
						this.enums.push(e);
						this.outNode=ast_GmlNodeDef_Block(tk[2],[]);
						break;
					case 4:
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						if(this.offset>=this.length)return this.errorAt("Expected a then-expression",this.source.eof);
						var _g4=this.tokens[this.offset];
						if(_g4[1]==9){
							if(_g4[3]==5)this.offset+=1;
						}
						if(this.buildLine())return true;
						x2=this.outNode;
						i=this.offset;
						while(this.offset<this.length){
							switch(this.tokens[this.offset][1]){
								case 27:case 28:case 29:
									this.offset+=1;
									continue;
							}
							break;
						}
						if(this.offset<this.length){
							var _g15=this.tokens[this.offset];
							if(_g15[1]==9){
								if(_g15[3]==6){
									this.offset+=1;
									if(this.buildLine())return true;
									x=this.outNode;
								}else {
									this.offset=i;
									x=null;
								}
							}else {
								this.offset=i;
								x=null;
							}
						}else {
							this.offset=i;
							x=null;
						}
						this.outNode=ast_GmlNodeDef_IfThen(tk[2],x1,x2,x);
						break;
					case 7:
						var d7=tk[2];
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						var cc=[];
						var c=null;
						if(this.offset>=this.length){
							return this.errorAt("Expected switch-block body",this.source.eof);
						}else if(this.tokens[this.offset][1]==24){
							this.offset+=1;
						}else return this.error("Expected switch-block body",this.tokens[this.offset]);
						if(this.offset>=this.length)return this.errorAt("Expected switch-block contents",this.source.eof);
						var _g6=this.tokens[this.offset];
						switch(_g6[1]){
							case 9:
								switch(_g6[3]){
									case 8:case 9:break;
									default:
										var tk4=this.tokens[this.offset];
										return this.error("Expected `case` or `default`, got "+tk4[0],tk4);
								}
								break;
							case 27:case 28:case 29:break;
							default:
								var tk5=this.tokens[this.offset];
								return this.error("Expected `case` or `default`, got "+tk5[0],tk5);
						}
						proc=true;
						x2=null;
						nodes=null;
						var pre=[];
						while(this.offset<this.length&&proc){
							var _g16=this.tokens[this.offset];
							switch(_g16[1]){
								case 9:
									switch(_g16[3]){
										case 8:
											this.offset+=1;
											if(this.buildExpr(0))return true;
											if(this.offset>=this.length){
												return this.errorAt("Expected a colon",this.source.eof);
											}else if(this.tokens[this.offset][1]==6){
												this.offset+=1;
											}else return this.error("Expected a colon",this.tokens[this.offset]);
											nodes=[this.outNode];
											while(this.offset<this.length){
												var _g18=this.tokens[this.offset];
												if(_g18[1]==9){
													if(_g18[3]==8){
														this.offset+=1;
														if(this.buildExpr(0))return true;
														if(this.offset>=this.length){
															return this.errorAt("Expected a colon",this.source.eof);
														}else if(this.tokens[this.offset][1]==6){
															this.offset+=1;
														}else return this.error("Expected a colon",this.tokens[this.offset]);
														nodes.push(this.outNode);
														continue;
													}
												}
												break;
											}
											c={
												values:nodes,
												expr:null,
												pre:pre
											};
											cc.push(c);
											nodes=[];
											pre=[];
											c.expr=ast_GmlNodeDef_Block(_g16[2],nodes);
											break;
										case 9:
											this.offset+=1;
											if(this.offset>=this.length){
												return this.errorAt("Expected a colon",this.source.eof);
											}else if(this.tokens[this.offset][1]==6){
												this.offset+=1;
											}else return this.error("Expected a colon",this.tokens[this.offset]);
											nodes=[];
											x2=ast_GmlNodeDef_Block(_g16[2],nodes);
											break;
										default:
											if(this.buildLine())return true;
											nodes.push(this.outNode);
									}
									break;
								case 25:
									this.offset+=1;
									proc=false;
									break;
								case 28:
									this.offset+=1;
									pre.push(ast_GmlNodeDef_CommentLine(_g16[2],_g16[3]));
									break;
								case 27:
									this.offset+=1;
									pre.push(ast_GmlNodeDef_CommentLine(_g16[2],_g16[3]));
									break;
								case 29:
									this.offset+=1;
									pre.push(ast_GmlNodeDef_CommentBlock(_g16[2],_g16[3]));
									break;
								default:
									if(this.buildLine())return true;
									nodes.push(this.outNode);
							}
						}
						if(proc)return this.errorAt("Unclosed switch-block",d7);
						this.outNode=ast_GmlNodeDef_Switch(d7,x1,cc,x2);
						break;
					case 14:
						if(this.offset>=this.length)return this.errorAt("Expected for-loop header",this.source.eof);
						if(this.tokens[this.offset][1]==20){
							this.offset+=1;
							proc=true;
						}else proc=false;
						if(this.buildLine())return true;
						x=this.outNode;
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						if(this.offset>=this.length)return this.errorAt("Expected for-loop post-action",this.source.eof);
						if(this.tokens[this.offset][1]==3)this.offset+=1;
						if(this.buildLine())return true;
						x2=this.outNode;
						if(proc){
							if(this.tokens[this.offset][1]==21){
								this.offset+=1;
							}else {
								var tk8=this.tokens[this.offset];
								return this.error("Expected a closing parenthesis, got "+tk8[0],tk8);
							}
						}
						if(this.buildLine())return true;
						this.outNode=ast_GmlNodeDef_For(tk[2],x,x1,x2,this.outNode);
						break;
					case 11:
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						if(this.buildLine())return true;
						this.outNode=ast_GmlNodeDef_While(tk[2],x1,this.outNode);
						break;
					case 10:
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						if(this.buildLine())return true;
						this.outNode=ast_GmlNodeDef_Repeat(tk[2],x1,this.outNode);
						break;
					case 13:
						var d13=tk[2];
						if(this.buildLine())return true;
						x1=this.outNode;
						if(this.offset>=this.length)return this.errorAt("Expected a `while` or `until`",this.source.eof);
						var _g7=this.tokens[this.offset];
						if(_g7[1]==9){
							switch(_g7[3]){
								case 11:
									this.offset+=1;
									if(this.buildExpr(0))return true;
									this.outNode=ast_GmlNodeDef_DoWhile(d13,x1,this.outNode);
									break;
								case 12:
									this.offset+=1;
									if(this.buildExpr(0))return true;
									this.outNode=ast_GmlNodeDef_DoUntil(d13,x1,this.outNode);
									break;
								default:
									var tk6=this.tokens[this.offset];
									return this.error("Expected a `while` or `until`, got "+tk6[0],tk6);
							}
						}else {
							var tk7=this.tokens[this.offset];
							return this.error("Expected a `while` or `until`, got "+tk7[0],tk7);
						}
						break;
					case 15:
						if(this.buildExpr(0))return true;
						x1=this.outNode;
						if(this.buildLine())return true;
						this.outNode=ast_GmlNodeDef_With(tk[2],x1,this.outNode);
						break;
					case 17:this.outNode=ast_GmlNodeDef_Break(tk[2]);break;
					case 16:this.outNode=ast_GmlNodeDef_Continue(tk[2]);break;
					case 19:this.outNode=ast_GmlNodeDef_Exit(tk[2]);break;
					case 18:
						var d18=tk[2];
						var _g9=this.tokens[this.offset];
						switch(_g9[1]){
							case 25:this.outNode=ast_GmlNodeDef_Exit(_g9[2]);break;
							case 3:this.outNode=ast_GmlNodeDef_Exit(_g9[2]);break;
							default:
								if(this.buildExpr(0))return true;
								this.outNode=ast_GmlNodeDef_Return(d18,this.outNode);
						}
						break;
					case 20:
						if(this.buildExpr(0))return true;
						this.outNode=ast_GmlNodeDef_Wait(tk[2],this.outNode);
						break;
					case 26:this.outNode=ast_GmlNodeDef_Debugger(tk[2]);break;
					case 21:
						if(this.buildExpr(0))return true;
						this.outNode=ast_GmlNodeDef_Yield(tk[2],this.outNode,-1);
						break;
					case 22:
						var d24=tk[2];
						if(this.buildExpr(0))return true;
						var _g10=this.outNode;
						switch(_g10[1]){
							case 7:this.outNode=ast_GmlNodeDef_UserLabel(d24,_g10[3]);break;
							case 2:this.outNode=ast_GmlNodeDef_UserLabel(d24,_g10[3]);break;
							default:return this.expectNode("a label name",this.outNode);
						}
						if(this.offset<this.length){
							if(this.tokens[this.offset][1]==6)this.offset+=1;
						}
						break;
					case 23:
						var d25=tk[2];
						if(this.buildExpr(0))return true;
						var _g20=this.outNode;
						switch(_g20[1]){
							case 7:this.outNode=ast_GmlNodeDef_UserJump(d25,_g20[3]);break;
							case 2:this.outNode=ast_GmlNodeDef_UserJump(d25,_g20[3]);break;
							default:return this.expectNode("a label name",this.outNode);
						}
						break;
					default:unknown=true;
				}
				break;
			case 1:
				var _g=this.tokens[this.offset++];
				if(_g[1]==10){
					if(this.buildExpr(0))return true;
					var i1=this.macroNames.length;
					this.macroNames[i1]=_g[3];
					this.macroNodes[i1]=this.outNode;
					this.outNode=ast_GmlNodeDef_Block(tk[2],[]);
				}else this.error("Expected a macro name",this.tokens[this.offset]);
				break;
			case 24:
				var start=tk[2];
				proc=true;
				nodes=[];
				if(this.offset<this.length){
					var _g22=this.tokens[this.offset];
					if(_g22[1]==27){
						nodes.push(ast_GmlNodeDef_CommentLine(_g22[2],_g22[3]));
						this.offset+=1;
					}
				}
				while(proc&&this.offset<this.length){
					var _g23=this.tokens[this.offset];
					switch(_g23[1]){
						case 29:
							switch(_g23[4]){
								case true:
									this.offset+=1;
									nodes.push(ast_GmlNodeDef_CommentBlock(_g23[2],_g23[3]));
									break;
								case false:
									if(this.buildLine())return true;
									nodes.push(ast_GmlNodeDef_CommentBlockPre(_g23[2],_g23[3],this.outNode,false));
									break;
							}
							break;
						case 25:
							this.offset+=1;
							proc=false;
							break;
						case 28:
							this.offset+=1;
							nodes.push(ast_GmlNodeDef_CommentLine(_g23[2],_g23[3]));
							break;
						default:
							if(this.buildLine())return true;
							nodes.push(this.outNode);
					}
				}
				if(proc)return this.errorAt("Expected a closing bracket.",start);
				this.outNode=ast_GmlNodeDef_Block(start,nodes);
				break;
			case 28:
				if(this.offset<this.length){
					if(this.buildLine())return true;
					this.outNode=ast_GmlNodeDef_CommentLineSep(tk[2],tk[3],this.outNode);
				}else this.outNode=ast_GmlNodeDef_CommentLine(tk[2],tk[3]);
				break;
			case 27:
				if(this.buildLine())return true;
				this.outNode=ast_GmlNodeDef_CommentLinePre(tk[2],tk[3],this.outNode);
				break;
			case 29:
				if(this.offset<this.length){
					if(this.buildLine())return true;
					this.outNode=ast_GmlNodeDef_CommentBlockPre(tk[2],tk[3],this.outNode,tk[4]);
				}else this.outNode=ast_GmlNodeDef_CommentBlock(tk[2],tk[3]);
				break;
			default:unknown=true;
		}
		if(unknown)this.offset-=1;
		if(unknown){
			if(this.buildExpr(5))return true;
			if(this.offset<this.length){
				var _g24=this.tokens[this.offset];
				if(_g24[1]==19){
					x=this.outNode;
					this.offset+=1;
					if(this.buildExpr(0))return true;
					this.outNode=ast_GmlNodeDef_SetOp(_g24[2],_g24[3],x,this.outNode);
				}else if(!ast_GmlNodeTools_isStatement(this.outNode))return this.expectNode("a statement",this.outNode);
			}else if(!ast_GmlNodeTools_isStatement(this.outNode))return this.expectNode("a statement",this.outNode);
		}
		while(this.offset<this.length){
			if(this.tokens[this.offset][1]==3){
				this.offset+=1;
				continue;
			}
			break;
		}
		if(this.offset<this.length){
			var _g26=this.tokens[this.offset];
			if(_g26[1]==27){
				this.offset+=1;
				this.outNode=ast_GmlNodeDef_CommentLinePost(_g26[2],this.outNode,_g26[3]);
			}
		}
		return false;
	},
	buildOuter:function(name,namedArgs,namedArgc){
		if(namedArgc==null)namedArgc=0;
		var scr=new ast_GmlScript(this.source,name,(this.offset>=this.length)?this.source.eof:this.tokens[this.offset][2]);
		if(namedArgs==null)namedArgs=Object.create(null);
		scr.namedArgs=namedArgs;
		scr.arguments=namedArgc;
		this.scripts.push(scr);
		var nodes=[];
		var proc=true;
		while(this.offset<this.length){
			var _g=this.tokens[this.offset];
			switch(_g[1]){
				case 0:break;
				case 28:
					nodes.push(ast_GmlNodeDef_CommentLine(_g[2],_g[3]));
					this.offset+=1;
					continue;
				default:
					if(this.buildLine())return true;
					nodes.push(this.outNode);
					continue;
			}
			break;
		}
		if(nodes.length>1){
			scr.node=ast_GmlNodeDef_Block(nodes[0][2],nodes);
		}else if(nodes.length==1){
			scr.node=nodes[0];
		}else scr.node=ast_GmlNodeDef_Block(this.source.eof,nodes);
		return false;
	},
	buildLoop:function(first){
		if(this.buildOuter(first))return true;
		while(this.offset<this.length){
			var tk=this.tokens[this.offset];
			if(tk[1]==0){
				this.offset+=1;
				var nextName=tk[3];
				var nextArgs=null;
				var nextArgc=0;
				if(!(tk[4]||this.offset>=this.length)){
					if(this.tokens[this.offset][1]==20){
						this.offset+=1;
						nextArgs=Object.create(null);
						var proc=true;
						if(this.offset>=this.length)return this.errorAt("Expected script arguments",this.source.eof);
						if(this.tokens[this.offset][1]==21){
							this.offset+=1;
						}else while(proc&&this.offset<this.length){
							var _g11=this.tokens[this.offset];
							if(_g11[1]==10){
								var s=_g11[3];
								var nextArg=s;
								if(nextArgs[nextArg]!=null)return this.error("An argument named "+nextArg+" is already defined at position "+nextArgs[nextArg],this.tokens[this.offset]);
								nextArgs[s]=nextArgc;
								++nextArgc;
								this.offset+=1;
								switch(this.tokens[this.offset][1]){
									case 21:
										this.offset+=1;
										proc=false;
										break;
									case 4:this.offset+=1;break;
									default:
										var tk1=this.tokens[this.offset];
										return this.error("Expected a comma or closing parenthesis in script arguments, got "+tk1[0],tk1);
								}
							}else {
								var tk2=this.tokens[this.offset];
								return this.error("Expected an argument, got "+tk2[0],tk2);
							}
						}
					}
				}
				if(this.buildOuter(nextName,nextArgs,nextArgc))return true;
			}else return this.error("Expected A script declaration, got "+tk[0],tk);
		}
		return false;
	}
}
function GmlParser_error(text,pos){
	GmlParser_errorText=pos.toString()+": "+text;
	GmlParser_errorPos=pos;
	return null;
}
function GmlParser_run(src,temStart){
	if(temStart==null)temStart=-1;
	var z, s, i, n, zi, row, rowStart, pos, tks;
	var out=[];
	if(temStart>=0){
		row=GmlParser_temRow;
		rowStart=GmlParser_temRowStart;
		pos=temStart;
	}else {
		row=1;
		rowStart=0;
		pos=0;
	}
	var file=src.name;
	var code=src.code;
	var sb=null;
	var len=src.length;
	var checkLine=false;
	var brackets=0;
	while(pos<len){
		var c=code.charCodeAt(pos++);
		switch(c){
			case 9:case 13:case 32:continue;
			case 10:
				if(checkLine){
					i=out.length-1;
					var _g=out[i];
					if(_g[1]==0){
						if(_g[4]==false)out[i]=ast_GmlToken_Header(_g[2],_g[3],true);
					}
				}
				++row;
				rowStart=pos;
				continue;
		}
		var start=pos-1;
		var d=new ast_GmlPos(src,row,pos-rowStart);
		var op;
		switch(c){
			case 59:out.push(ast_GmlToken_Semico(d));break;
			case 44:out.push(ast_GmlToken_Comma(d));break;
			case 46:
				c=code.charCodeAt(pos);
				if(c>=48&&c<=57){
					while(true){
						++pos;
						c=code.charCodeAt(pos);
						if(!(c>=48&&c<=57))break;
					}
					s=code.substring(start,pos);
					out.push(ast_GmlToken_Number(d,parseFloat(s),s));
				}else out.push(ast_GmlToken_Period(d));
				break;
			case 58:out.push(ast_GmlToken_Colon(d));break;
			case 63:out.push(ast_GmlToken_QMark(d));break;
			case 64:out.push(ast_GmlToken_AtSign(d));break;
			case 61:
				if(code.charCodeAt(pos)==61){
					++pos;
					out.push(ast_GmlToken_BinOp(d,64));
				}else out.push(ast_GmlToken_SetOp(d,-1));
				break;
			case 43:
				switch(code.charCodeAt(pos)){
					case 61:
						++pos;
						out.push(ast_GmlToken_SetOp(d,16));
						break;
					case 43:
						++pos;
						out.push(ast_GmlToken_Adjfix(d,true));
						break;
					default:out.push(ast_GmlToken_BinOp(d,16));
				}
				break;
			case 45:
				switch(code.charCodeAt(pos)){
					case 61:
						++pos;
						out.push(ast_GmlToken_SetOp(d,17));
						break;
					case 45:
						++pos;
						out.push(ast_GmlToken_Adjfix(d,false));
						break;
					default:out.push(ast_GmlToken_BinOp(d,17));
				}
				break;
			case 47:
				switch(code.charCodeAt(pos)){
					case 47:
						start=++pos;
						while(pos<len){
							i=code.charCodeAt(pos);
							if(i==10||i==13){
								if(code.charCodeAt(start)==47)out.push(ast_GmlToken_CommentLine(d,code.substring(start,pos)));
								break;
							}else ++pos;
						}
						break;
					case 42:
						++pos;
						while(true){
							c=code.charCodeAt(pos);
							if(c==10){
								++row;
								rowStart=pos;
							}
							++pos;
							if(pos<len){
								z=true;
								if(c==42)switch(code.charCodeAt(pos)){
									case 47:z=false;break;
									case 92:
										if(pos+1<len&&code.charCodeAt(pos+1)==47){
											++pos;
											z=false;
										}
										break;
								}
							}else z=false;
							if(!z)break;
						}
						i=pos;
						z=true;
						++pos;
						while(++i<len){
							switch(code.charCodeAt(i)){
								case 9:case 32:continue;
								case 10:case 13:break;
								default:z=false;
							}
							break;
						}
						break;
					case 61:
						++pos;
						out.push(ast_GmlToken_SetOp(d,1));
						break;
					default:
						op=1;
						if(code.charCodeAt(pos)==61){
							++pos;
							out.push(ast_GmlToken_SetOp(d,op));
						}else out.push(ast_GmlToken_BinOp(d,op));
				}
				break;
			case 42:
				op=0;
				if(code.charCodeAt(pos)==61){
					++pos;
					out.push(ast_GmlToken_SetOp(d,op));
				}else out.push(ast_GmlToken_BinOp(d,op));
				break;
			case 37:
				op=2;
				if(code.charCodeAt(pos)==61){
					++pos;
					out.push(ast_GmlToken_SetOp(d,op));
				}else out.push(ast_GmlToken_BinOp(d,op));
				break;
			case 38:
				if(code.charCodeAt(pos)==38){
					++pos;
					op=80;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}else {
					op=49;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}
				break;
			case 124:
				if(code.charCodeAt(pos)==124){
					++pos;
					op=96;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}else {
					op=48;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}
				break;
			case 94:
				if(code.charCodeAt(pos)==94){
					++pos;
					op=65;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}else {
					op=50;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}
				break;
			case 62:
				switch(code.charCodeAt(pos)){
					case 61:
						++pos;
						out.push(ast_GmlToken_BinOp(d,69));
						break;
					case 62:
						++pos;
						op=33;
						if(code.charCodeAt(pos)==61){
							++pos;
							out.push(ast_GmlToken_SetOp(d,op));
						}else out.push(ast_GmlToken_BinOp(d,op));
						break;
					default:out.push(ast_GmlToken_BinOp(d,68));
				}
				break;
			case 60:
				switch(code.charCodeAt(pos)){
					case 61:
						++pos;
						out.push(ast_GmlToken_BinOp(d,67));
						break;
					case 60:
						++pos;
						op=32;
						if(code.charCodeAt(pos)==61){
							++pos;
							out.push(ast_GmlToken_SetOp(d,op));
						}else out.push(ast_GmlToken_BinOp(d,op));
						break;
					case 62:
						++pos;
						op=65;
						if(code.charCodeAt(pos)==61){
							++pos;
							out.push(ast_GmlToken_SetOp(d,op));
						}else out.push(ast_GmlToken_BinOp(d,op));
						break;
					default:out.push(ast_GmlToken_BinOp(d,66));
				}
				break;
			case 33:
				if(code.charCodeAt(pos)==61){
					++pos;
					op=65;
					if(code.charCodeAt(pos)==61){
						++pos;
						out.push(ast_GmlToken_SetOp(d,op));
					}else out.push(ast_GmlToken_BinOp(d,op));
				}else out.push(ast_GmlToken_UnOp(d,1));
				break;
			case 126:out.push(ast_GmlToken_UnOp(d,2));break;
			case 40:out.push(ast_GmlToken_ParOpen(d));break;
			case 41:out.push(ast_GmlToken_ParClose(d));break;
			case 91:out.push(ast_GmlToken_SqbOpen(d));break;
			case 93:out.push(ast_GmlToken_SqbClose(d));break;
			case 123:
				++brackets;
				out.push(ast_GmlToken_CubOpen(d));
				break;
			case 125:
				--brackets;
				if(temStart>=0&&brackets<0){
					if(temStart>=0){
						GmlParser_temEnd=pos;
						GmlParser_temRow=row;
						GmlParser_temRowStart=rowStart;
					}
					return out;
				}else out.push(ast_GmlToken_CubClose(d));
				break;
			case 34:
				n=pos;
				for(i=code.charCodeAt(pos);i!=c&&pos<len;i=code.charCodeAt(pos)){
					if(i==10){
						++row;
						rowStart=pos;
					}
					++pos;
				}
				if(pos<len){
					s=code.substring(n,pos++);
				}else {
					GmlParser_error("Unclosed string",d);
					s=null;
				}
				if(s==null)return null;
				out.push(ast_GmlToken_CString(d,code.substring(start+1,pos-1)));
				break;
			case 39:
				n=pos;
				for(i=code.charCodeAt(pos);i!=c&&pos<len;i=code.charCodeAt(pos)){
					if(i==10){
						++row;
						rowStart=pos;
					}
					++pos;
				}
				if(pos<len){
					s=code.substring(n,pos++);
				}else {
					GmlParser_error("Unclosed string",d);
					s=null;
				}
				if(s==null)return null;
				out.push(ast_GmlToken_CString(d,code.substring(start+1,pos-1)));
				break;
			case 96:
				start=pos;
				c=code.charCodeAt(pos);
				out.push(ast_GmlToken_ParOpen(d));
				for(z=false;c!=96&&pos<len;c=code.charCodeAt(pos)){
					++pos;
					if(c==10){
						++row;
						rowStart=pos;
					}else if(c==36){
						c=code.charCodeAt(pos);
						if(c==123){
							++pos;
							d=new ast_GmlPos(src,row,pos-rowStart);
							if(z){
								out.push(ast_GmlToken_BinOp(d,18));
							}else z=true;
							out.push(ast_GmlToken_CString(d,code.substring(start,pos-2)));
							GmlParser_temRow=row;
							GmlParser_temRowStart=rowStart;
							tks=GmlParser_run(src,pos);
							if(tks==null)return null;
							row=GmlParser_temRow;
							rowStart=GmlParser_temRowStart;
							pos=GmlParser_temEnd;
							start=pos;
							out.push(ast_GmlToken_BinOp(d,18));
							out.push(ast_GmlToken_ParOpen(d));
							d=new ast_GmlPos(src,row,pos-rowStart);
							n=tks.length;
							for(i=0;i<n;++i)out.push(tks[i]);
							out.push(ast_GmlToken_ParClose(d));
						}
					}
				}
				if(pos>=len){
					return GmlParser_error("Unclosed string",d);
				}else ++pos;
				d=new ast_GmlPos(src,row,pos-rowStart);
				if(z)out.push(ast_GmlToken_BinOp(d,18));
				out.push(ast_GmlToken_CString(d,code.substring(start,pos-1)));
				out.push(ast_GmlToken_ParClose(d));
				break;
			case 35:
				start=pos;
				while(pos<len){
					c=code.charCodeAt(pos);
					if(c==95||c>=97&&c<=122||c>=65&&c<=90||c>=48&&c<=57){
						++pos;
					}else break;
				}
				switch(code.substring(start,pos)){
					case "define":
						start=pos;
						while(pos<len){
							c=code.charCodeAt(pos);
							if(c==32||c==9){
								++pos;
							}else break;
						}
						if((c==95||c>=97&&c<=122||c>=65&&c<=90)&&pos<len){
							start=pos;
							++pos;
							while(pos<len){
								c=code.charCodeAt(pos);
								if(c==95||c>=97&&c<=122||c>=65&&c<=90||c>=48&&c<=57){
									++pos;
								}else break;
							}
							out.push(ast_GmlToken_Header(d,code.substring(start,pos),false));
							checkLine=true;
						}else return GmlParser_error("Expected a script name",d);
						break;
					case "macro":out.push(ast_GmlToken_Macro(d));break;
					case "endregion":case "region":
						while(pos<len){
							i=code.charCodeAt(pos);
							if(i==10||i==13){
								break;
							}else ++pos;
						}
						break;
					case "gmcr":break;
					default:
						out.push(ast_GmlToken_Hash(d));
						pos=start;
				}
				break;
			case 36:
				while(pos<len){
					c=code.charCodeAt(pos);
					if(c>=48&&c<=57||c>=97&&c<=102||c>=65&&c<=70){
						++pos;
					}else break;
				}
				s="0x"+code.substring(start+1,pos);
				out.push(ast_GmlToken_Number(d,Std_parseInt(s),s));
				break;
			default:
				if(c>=97&&c<=122||c>=65&&c<=90||c==95){
					while(pos<len){
						c=code.charCodeAt(pos);
						if(c==95||c>=97&&c<=122||c>=65&&c<=90||c>=48&&c<=57){
							++pos;
						}else break;
					}
					s=code.substring(start,pos);
					switch(s){
						case "global":out.push(ast_GmlToken_Keyword(d,0));break;
						case "true":out.push(ast_GmlToken_Number(d,1,null));break;
						case "false":out.push(ast_GmlToken_Number(d,0,null));break;
						case "all":out.push(ast_GmlToken_Number(d,-3,null));break;
						case "noone":out.push(ast_GmlToken_Number(d,-4,null));break;
						case "undefined":out.push(ast_GmlToken_Undefined(d));break;
						case "null":out.push(ast_GmlToken_Undefined(d));break;
						case "begin":out.push(ast_GmlToken_CubOpen(d));break;
						case "end":out.push(ast_GmlToken_CubClose(d));break;
						case "globalvar":out.push(ast_GmlToken_Keyword(d,1));break;
						case "var":out.push(ast_GmlToken_Keyword(d,2));break;
						case "enum":out.push(ast_GmlToken_Keyword(d,3));break;
						case "if":out.push(ast_GmlToken_Keyword(d,4));break;
						case "then":out.push(ast_GmlToken_Keyword(d,5));break;
						case "else":out.push(ast_GmlToken_Keyword(d,6));break;
						case "switch":out.push(ast_GmlToken_Keyword(d,7));break;
						case "case":out.push(ast_GmlToken_Keyword(d,8));break;
						case "default":out.push(ast_GmlToken_Keyword(d,9));break;
						case "for":out.push(ast_GmlToken_Keyword(d,14));break;
						case "repeat":out.push(ast_GmlToken_Keyword(d,10));break;
						case "while":out.push(ast_GmlToken_Keyword(d,11));break;
						case "do":out.push(ast_GmlToken_Keyword(d,13));break;
						case "until":out.push(ast_GmlToken_Keyword(d,12));break;
						case "with":out.push(ast_GmlToken_Keyword(d,15));break;
						case "exit":out.push(ast_GmlToken_Keyword(d,19));break;
						case "return":out.push(ast_GmlToken_Keyword(d,18));break;
						case "break":out.push(ast_GmlToken_Keyword(d,17));break;
						case "continue":out.push(ast_GmlToken_Keyword(d,16));break;
						case "yield":out.push(ast_GmlToken_Keyword(d,21));break;
						case "label":out.push(ast_GmlToken_Keyword(d,22));break;
						case "goto":out.push(ast_GmlToken_Keyword(d,23));break;
						case "div":out.push(ast_GmlToken_BinOp(d,3));break;
						case "mod":out.push(ast_GmlToken_BinOp(d,2));break;
						case "and":out.push(ast_GmlToken_BinOp(d,80));break;
						case "or":out.push(ast_GmlToken_BinOp(d,96));break;
						case "xor":out.push(ast_GmlToken_BinOp(d,65));break;
						case "not":out.push(ast_GmlToken_UnOp(d,1));break;
						case "in":out.push(ast_GmlToken_In(d));break;
						case "argument":out.push(ast_GmlToken_Keyword(d,24));break;
						case "argument_count":out.push(ast_GmlToken_Keyword(d,25));break;
						default:
							if(StringTools_startsWith(s,"argument")){
								zi=Std_parseInt(s.substring(8));
								if(zi!=null){
									out.push(ast_GmlToken_ArgConst(d,zi));
								}else out.push(ast_GmlToken_Ident(d,s));
							}else out.push(ast_GmlToken_Ident(d,s));
					}
				}else if(c>=48&&c<=57||c==46){
					if(code.charCodeAt(pos)==120){
						++pos;
						while(pos<len){
							c=code.charCodeAt(pos);
							if(c>=48&&c<=57||c>=97&&c<=102||c>=65&&c<=70){
								++pos;
							}else break;
						}
						s=code.substring(start,pos);
						out.push(ast_GmlToken_Number(d,Std_parseInt(s),s));
					}else {
						--pos;
						z=false;
						s=null;
						while(pos<len){
							c=code.charCodeAt(pos);
							if(c==46){
								if(z){
									return GmlParser_error("Extra dot in a number",d);
								}else {
									++pos;
									c=code.charCodeAt(pos);
									if(c==95||c>=97&&c<=122||c>=65&&c<=90){
										s=code.substring(start,pos-2);
										out.push(ast_GmlToken_Number(d,parseFloat(s),s));
										d=new ast_GmlPos(src,row,pos-rowStart);
										out.push(ast_GmlToken_Period(d));
										break;
									}
									z=true;
								}
							}else if(c>=48&&c<=57){
								++pos;
							}else break;
						}
						if(s==null){
							while(code.charCodeAt(start)==48){
								++start;
								if(start>=pos){
									--start;
									break;
								}else if(code.charCodeAt(start)==46){
									--start;
									break;
								}
							}
							s=code.substring(start,pos);
							out.push(ast_GmlToken_Number(d,parseFloat(s),s));
						}
					}
				}else return GmlParser_error("Unexpected character `"+String.fromCharCode(c)+"`",d);
		}
	}
	if(temStart>=0){
		GmlParser_temEnd=pos;
		GmlParser_temRow=row;
		GmlParser_temRowStart=rowStart;
	}
	return out;
}
function GmlPrint_quoted(s){
	s=StringTools_replace(s,"\\","\\\\");
	s=StringTools_replace(s,"\n","\\n");
	if(s.indexOf('"')<0){
		return '"'+s+'"';
	}else if(s.indexOf("'")<0){
		return "'"+s+"'";
	}else throw new js__Boot_HaxeError("Can't print `"+s+"`");
}
function GmlPrint_inst(r,q,stack,f){
	switch(q[1]){
		case 34:r.b+="global";break;
		case 9:r.b+=Std_string(GmlPrint_other);break;
		case 8:r.b+=Std_string(GmlPrint_self);break;
		default:GmlPrint_node(r,q,stack,0);
	}
}
function GmlPrint_index(r,q,stack,f){
	GmlPrint_node(r,q,stack,2);
}
function GmlPrint_node(r,o,stack,flags){
	stack.unshift(o);
	var tx, i, n, k, s, s2, z, z2, zi, q, q2, w;
	var crWasLabel=GmlPrint_crLabelId>=0;
	var _g=o;
	if(_g[1]==104){
		var i1=_g[3];
		if(!crWasLabel)GmlPrint_crLabelId=i1;
	}else GmlPrint_crLabelId=-1;
	var _g1=o;
	switch(_g1[1]){
		case 100:r.b+="break";break;
		case 8:r.b+="self";break;
		case 102:r.b+="debugger";break;
		case 101:r.b+="continue";break;
		case 9:r.b+="other";break;
		case 0:r.b+="undefined";break;
		case 1:
			var v=_g1[3];
			s=_g1[4];
			if(s!=null){
				r.b+=(s==null)?"null":""+s;
			}else r.b+=(v==null)?"null":""+v;
			break;
		case 2:r.b+=Std_string(GmlPrint_quoted(_g1[3]));break;
		case 3:
			var c=_g1[4];
			r.b+=Std_string(c.value);
			r.b+="/* ";
			r.b+=Std_string(_g1[3].name);
			r.b+=".";
			r.b+=Std_string(c.name);
			r.b+=" */";
			break;
		case 4:
			w=_g1[3];
			n=w.length;
			if(gmcr_CrCore_v2){
				r.b+="[";
			}else r.b+="array_from_values(";
			if(n>0){
				GmlPrint_node(r,w[0],stack,2);
				for(i=1;i<n;++i){
					r.b+=", ";
					GmlPrint_node(r,w[i],stack,2);
				}
			}
			if(gmcr_CrCore_v2){
				r.b+="]";
			}else r.b+=")";
			break;
		case 5:
			var kw=_g1[3];
			w=_g1[4];
			n=w.length;
			r.b+="{";
			if(n>0){
				r.b+=" ";
				r.b+=Std_string(kw[0]);
				r.b+=": ";
				GmlPrint_node(r,w[0],stack,2);
				for(i=1;i<n;++i){
					r.b+=", ";
					r.b+=Std_string(kw[i]);
					r.b+=": ";
					GmlPrint_node(r,w[i],stack,2);
				}
			}
			r.b+=" ";
			r.b+="}";
			r.semicoAfter=r.b.length;
			break;
		case 84:
			var v25=_g1[4];
			var s45=_g1[3];
			r.b+="var ";
			r.b+=(s45==null)?"null":""+s45;
			if(v25!=null){
				r.b+=" = ";
				GmlPrint_node(r,v25,stack,2);
			}
			break;
		case 6:break;
		case 17:
			var s5=_g1[3];
			r.b+=(s5==null)?"null":""+s5;
			r.b+="(";
			r.b+=Std_string(GmlPrint_self);
			r.b+=", ";
			r.b+=Std_string(GmlPrint_other);
			w=_g1[4];
			n=w.length;
			for(i=0;i<n;++i){
				r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 19:
			r.b+="gml$scripts[";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+="](";
			r.b+=Std_string(GmlPrint_self);
			r.b+=", ";
			r.b+=Std_string(GmlPrint_other);
			w=_g1[4];
			n=w.length;
			for(i=0;i<n;++i){
				r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 22:
			var s7=_g1[4];
			r.b+=(s7==null)?"null":""+s7;
			r.b+="(";
			GmlPrint_inst(r,_g1[3],stack,flags);
			w=_g1[5];
			n=w.length;
			for(i=0;i<n;++i){
				r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 18:
			var s6=_g1[4];
			r.b+=(s6==null)?"null":""+s6;
			r.b+="(";
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=", ";
			r.b+=Std_string(GmlPrint_self);
			w=_g1[5];
			n=w.length;
			for(i=0;i<n;++i){
				r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 20:
			q=_g1[3];
			s=_g1[4];
			if(ast_GmlNodeTools_isSimple(q)){
				r.b+="gml$scripts[";
				GmlPrint_inst(r,q,stack,flags);
				r.b+=".js$";
				r.b+=(s==null)?"null":""+s;
				r.b+="](";
				GmlPrint_inst(r,q,stack,flags);
				r.b+=", ";
				r.b+=Std_string(GmlPrint_self);
			}else {
				r.b+="gml$fieldcall(";
				GmlPrint_inst(r,q,stack,flags);
				r.b+=", 'js$";
				r.b+=(s==null)?"null":""+s;
				r.b+="', ";
				r.b+=Std_string(GmlPrint_self);
			}
			w=_g1[5];
			n=w.length;
			for(i=0;i<n;++i){
				r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 21:
			s=_g1[3];
			r.b+=(s==null)?"null":""+s;
			r.b+="(";
			w=_g1[4];
			n=w.length;
			i=data_GmlAPI_instData[s];
			if(i!=null){
				r.b+=Std_string(GmlPrint_self);
				if(i>1){
					r.b+=", ";
					r.b+=Std_string(GmlPrint_other);
				}
				z=true;
			}else z=false;
			for(i=0;i<n;++i){
				if(z){
					r.b+=", ";
				}else z=true;
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 11:
			var scr=_g1[3];
			r.b+=Std_string(scr.index);
			r.b+="/* ";
			r.b+=Std_string(scr.name);
			r.b+=" */";
			break;
		case 12:
			s=_g1[3];
			if(data_GmlAPI_constVal!=null){
				var v2=data_GmlAPI_constVal[s];
				if(v2==null){
					r.b+=(s==null)?"null":""+s;
				}else if((typeof v2)=="string"){
					r.b+=Std_string(GmlPrint_quoted(v2));
				}else {
					r.b+=Std_string(v2);
					r.b+=" /* ";
					r.b+=(s==null)?"null":""+s;
					r.b+=" */";
				}
			}else r.b+=(s==null)?"null":""+s;
			break;
		case 28:
			if((flags&2)==0){
				r.b+="(";
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=" > 0.5)";
			}else {
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=" > 0.5";
			}
			break;
		case 29:
			if((flags&2)==0){
				r.b+="(";
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=" ? 1 : 0)";
			}else {
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=" ? 1 : 0";
			}
			break;
		case 30:
			if(_g1[5])r.b+="!";
			r.b+="gml$variable_instance_exists(";
			GmlPrint_node(r,_g1[4],stack,2);
			r.b+=", ";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=")";
			break;
		case 26:
			var o2=_g1[3];
			if((flags&2)==0)r.b+="(";
			if(o2!=3){
				GmlPrint_node(r,_g1[4],stack,0);
				r.b+=" ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(o2));
				r.b+=" ";
				GmlPrint_node(r,_g1[5],stack,0);
			}else {
				r.b+="div(";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=")";
			}
			if((flags&2)==0)r.b+=")";
			break;
		case 27:
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=" ";
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[3]));
			r.b+="= ";
			GmlPrint_node(r,_g1[5],stack,0);
			break;
		case 25:
			switch(_g1[4]){
				case 2:s="~";break;
				case 1:s="!";break;
				case 0:s="-";break;
			}
			r.b+=(s==null)?"null":""+s;
			GmlPrint_node(r,_g1[3],stack,0);
			break;
		case 23:
			r.b+=(_g1[4])?"++":"--";
			GmlPrint_node(r,_g1[3],stack,0);
			break;
		case 24:
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=(_g1[4])?"++":"--";
			break;
		case 13:
			var i2=_g1[3];
			if(GmlPrint_printScript.hasYield){
				r.b+="l_args";
				r.b+="[";
				r.b+=(i2==null)?"null":""+i2;
				r.b+="]";
			}else {
				r.b+="argument";
				r.b+=(i2==null)?"null":""+i2;
			}
			break;
		case 14:
			if(GmlPrint_printScript.hasYield){
				r.b+="l_args";
				r.b+="[";
				GmlPrint_index(r,_g1[3],stack,flags);
				r.b+="]";
			}else {
				r.b+="argument[";
				GmlPrint_index(r,_g1[3],stack,flags);
				r.b+="]";
			}
			break;
		case 15:
			if(GmlPrint_printScript.hasYield){
				r.b+="array_length_1d(";
				r.b+="l_args";
				r.b+=")";
			}else r.b+="argument_count";
			break;
		case 31:
			var s10=_g1[3];
			r.b+=(s10==null)?"null":""+s10;
			break;
		case 32:
			var s11=_g1[3];
			r.b+=(s11==null)?"null":""+s11;
			r.b+=" = ";
			GmlPrint_node(r,_g1[4],stack,2);
			break;
		case 33:
			var s12=_g1[3];
			r.b+=(s12==null)?"null":""+s12;
			r.b+=" ";
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[4]));
			r.b+="= ";
			GmlPrint_node(r,_g1[5],stack,2);
			break;
		case 34:
			var s14=_g1[3];
			r.b+="global.";
			r.b+=(s14==null)?"null":""+s14;
			break;
		case 35:
			var s15=_g1[3];
			r.b+="global.";
			r.b+=(s15==null)?"null":""+s15;
			r.b+=" = ";
			GmlPrint_node(r,_g1[4],stack,2);
			break;
		case 36:
			var s16=_g1[3];
			r.b+="global.";
			r.b+=(s16==null)?"null":""+s16;
			r.b+=" ";
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[4]));
			r.b+="= ";
			GmlPrint_node(r,_g1[5],stack,2);
			break;
		case 37:
			var s18=_g1[4];
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=".";
			r.b+=(s18==null)?"null":""+s18;
			break;
		case 38:
			var s19=_g1[4];
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=".";
			r.b+=(s19==null)?"null":""+s19;
			r.b+=" = ";
			GmlPrint_node(r,_g1[5],stack,2);
			break;
		case 39:
			var s20=_g1[4];
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=".";
			r.b+=(s20==null)?"null":""+s20;
			r.b+=" ";
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[5]));
			r.b+="= ";
			GmlPrint_node(r,_g1[6],stack,2);
			break;
		case 40:
			s=_g1[3];
			r.b+=(s==null)?"null":""+s;
			r.b+="_get(";
			if((data_GmlAPI_varFlags[s]&4)!=0)r.b+=Std_string(GmlPrint_self);
			r.b+=")";
			break;
		case 41:
			s=_g1[3];
			r.b+=(s==null)?"null":""+s;
			r.b+="_set(";
			if((data_GmlAPI_varFlags[s]&4)!=0){
				r.b+=Std_string(GmlPrint_self);
				r.b+=", ";
			}
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=")";
			break;
		case 42:
			var s22=_g1[3];
			r.b+=(s22==null)?"null":""+s22;
			r.b+="_aop(";
			if((data_GmlAPI_varFlags[s22]&4)!=0){
				r.b+=Std_string(GmlPrint_self);
				r.b+=", ";
			}
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[4]));
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=")";
			break;
		case 43:
			var s24=_g1[4];
			r.b+="get$";
			r.b+=(s24==null)?"null":""+s24;
			r.b+="(";
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=")";
			break;
		case 44:
			var s25=_g1[4];
			r.b+="set$";
			r.b+=(s25==null)?"null":""+s25;
			r.b+="(";
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=")";
			break;
		case 45:
			var s26=_g1[4];
			r.b+="aop$";
			r.b+=(s26==null)?"null":""+s26;
			r.b+="(";
			GmlPrint_inst(r,_g1[3],stack,flags);
			r.b+=", ";
			r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[5]));
			r.b+=", ";
			GmlPrint_node(r,_g1[6],stack,0);
			r.b+=")";
			break;
		case 46:
			var s28=_g1[3];
			r.b+="get$";
			r.b+=(s28==null)?"null":""+s28;
			r.b+="(";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=")";
			break;
		case 47:
			var s29=_g1[3];
			r.b+="set$";
			r.b+=(s29==null)?"null":""+s29;
			r.b+="(";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=")";
			break;
		case 48:
			var s30=_g1[3];
			r.b+="set$";
			r.b+=(s30==null)?"null":""+s30;
			r.b+="(";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[6],stack,0);
			r.b+=")";
			break;
		case 49:
			var x21=_g1[3];
			if(ast_GmlNodeTools_needsAf(x21)){
				r.b+="array_wget";
				r.b+="(";
				GmlPrint_node(r,x21,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x21,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="]";
			}
			break;
		case 50:
			var x22=_g1[3];
			if(ast_GmlNodeTools_needsAf(x22)){
				r.b+="array_set";
				r.b+="(";
				GmlPrint_node(r,x22,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x22,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="] = ";
				GmlPrint_node(r,_g1[5],stack,0);
			}
			break;
		case 51:
			var x23=_g1[3];
			if(ast_GmlNodeTools_needsAf(x23)){
				r.b+="array_aop";
				r.b+="(";
				GmlPrint_node(r,x23,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[5]));
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x23,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[5]));
				r.b+="= ";
				GmlPrint_node(r,_g1[6],stack,0);
			}
			break;
		case 52:
			var x24=_g1[3];
			if(ast_GmlNodeTools_needsAf(x24)){
				r.b+="array_prefix";
				r.b+="(";
				GmlPrint_node(r,x24,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[5])?"++":"--";
				GmlPrint_node(r,x24,stack,0);
				r.b+="[";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
			}
			break;
		case 53:
			var x25=_g1[3];
			if(ast_GmlNodeTools_needsAf(x25)){
				r.b+="array_postfix";
				r.b+="(";
				GmlPrint_node(r,x25,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x25,stack,0);
				r.b+="[";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
				r.b+=(_g1[5])?"++":"--";
			}
			break;
		case 54:
			var x26=_g1[3];
			if(ast_GmlNodeTools_needsAf(x26)){
				r.b+="array_get_2D";
				r.b+="(";
				GmlPrint_node(r,x26,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=")";
			}else {
				GmlPrint_node(r,x26,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
			}
			break;
		case 55:
			var x27=_g1[3];
			if(ast_GmlNodeTools_needsAf(x27)){
				r.b+="array_set_2D";
				r.b+="(";
				GmlPrint_node(r,x27,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,0);
				r.b+=")";
			}else {
				GmlPrint_node(r,x27,stack,0);
				r.b+="[";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+="] = ";
				GmlPrint_node(r,_g1[6],stack,2);
			}
			break;
		case 56:
			var x28=_g1[3];
			if(ast_GmlNodeTools_needsAf(x28)){
				r.b+="array_aop_2D";
				r.b+="(";
				GmlPrint_node(r,x28,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[6]));
				r.b+=", ";
				GmlPrint_node(r,_g1[7],stack,0);
				r.b+=")";
			}else {
				GmlPrint_node(r,x28,stack,0);
				r.b+="[";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[6]));
				r.b+="= ";
				GmlPrint_node(r,_g1[7],stack,2);
			}
			break;
		case 57:
			var x29=_g1[3];
			if(ast_GmlNodeTools_needsAf(x29)){
				r.b+="array_prefix_2D";
				r.b+="(";
				GmlPrint_node(r,x29,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[6])?"++":"--";
				GmlPrint_node(r,x29,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
			}
			break;
		case 58:
			var x30=_g1[3];
			if(ast_GmlNodeTools_needsAf(x30)){
				r.b+="array_postfix_2D";
				r.b+="(";
				GmlPrint_node(r,x30,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x30,stack,0);
				r.b+="[";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
				r.b+=(_g1[6])?"++":"--";
			}
			break;
		case 59:
			var x31=_g1[3];
			if(ast_GmlNodeTools_needsAf(x31)){
				r.b+="array_wget";
				r.b+="(";
				GmlPrint_node(r,x31,stack,2);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=")";
			}else {
				GmlPrint_node(r,x31,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="]";
			}
			break;
		case 60:
			var x32=_g1[3];
			if(ast_GmlNodeTools_needsAf(x32)){
				r.b+="array_set";
				r.b+="(";
				GmlPrint_node(r,x32,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x32,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="] = ";
				GmlPrint_node(r,_g1[5],stack,2);
			}
			break;
		case 61:
			var x33=_g1[3];
			if(ast_GmlNodeTools_needsAf(x33)){
				r.b+="array_aop";
				r.b+="(";
				GmlPrint_node(r,x33,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[5]));
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x33,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[5]));
				r.b+="= ";
				GmlPrint_node(r,_g1[6],stack,0);
			}
			break;
		case 62:
			var x34=_g1[3];
			if(ast_GmlNodeTools_needsAf(x34)){
				r.b+="array_prefix";
				r.b+="(";
				GmlPrint_node(r,x34,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[5])?"++":"--";
				GmlPrint_node(r,x34,stack,0);
				r.b+="[@";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
			}
			break;
		case 63:
			var x35=_g1[3];
			if(ast_GmlNodeTools_needsAf(x35)){
				r.b+="array_prefix";
				r.b+="(";
				GmlPrint_node(r,x35,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x35,stack,0);
				r.b+="[@";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
				r.b+=(_g1[5])?"++":"--";
			}
			break;
		case 64:
			var x36=_g1[3];
			if(ast_GmlNodeTools_needsAf(x36)){
				r.b+="array_get_2D";
				r.b+="(";
				GmlPrint_node(r,x36,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=")";
			}else {
				GmlPrint_node(r,x36,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
			}
			break;
		case 65:
			var x37=_g1[3];
			if(ast_GmlNodeTools_needsAf(x37)){
				r.b+="array_set_2D";
				r.b+="(";
				GmlPrint_node(r,x37,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x37,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="] = ";
				GmlPrint_node(r,_g1[6],stack,2);
			}
			break;
		case 66:
			var x38=_g1[3];
			if(ast_GmlNodeTools_needsAf(x38)){
				r.b+="array_aop_2D";
				r.b+="(";
				GmlPrint_node(r,x38,stack,0);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[6]));
				r.b+=", ";
				GmlPrint_node(r,_g1[7],stack,0);
				r.b+=")";
			}else {
				GmlPrint_node(r,x38,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[6]));
				r.b+="= ";
				GmlPrint_node(r,_g1[7],stack,2);
			}
			break;
		case 67:
			var x39=_g1[3];
			if(ast_GmlNodeTools_needsAf(x39)){
				r.b+="array_prefix_2D";
				r.b+="(";
				GmlPrint_node(r,x39,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[6])?"++":"--";
				GmlPrint_node(r,x39,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
			}
			break;
		case 68:
			var x40=_g1[3];
			if(ast_GmlNodeTools_needsAf(x40)){
				r.b+="array_postfix_2D";
				r.b+="(";
				GmlPrint_node(r,x40,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x40,stack,0);
				r.b+="[@";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
				r.b+=(_g1[6])?"++":"--";
			}
			break;
		case 69:
			r.b+="ds_list_find_value";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=")";
			break;
		case 70:
			r.b+="ds_list_set";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=")";
			break;
		case 71:
			var x43=_g1[3];
			if(ast_GmlNodeTools_needsAf(x43)){
				r.b+="ds_list_aop";
				r.b+="(";
				GmlPrint_node(r,x43,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[5]));
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x43,stack,0);
				r.b+="[|";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[5]));
				r.b+="= ";
				GmlPrint_node(r,_g1[6],stack,2);
			}
			break;
		case 72:
			var x44=_g1[3];
			if(ast_GmlNodeTools_needsAf(x44)){
				r.b+="ds_list_prefix";
				r.b+="(";
				GmlPrint_node(r,x44,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[5])?"++":"--";
				GmlPrint_node(r,x44,stack,0);
				r.b+="[|";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
			}
			break;
		case 73:
			var x45=_g1[3];
			if(ast_GmlNodeTools_needsAf(x45)){
				r.b+="ds_list_postfix";
				r.b+="(";
				GmlPrint_node(r,x45,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[5])?"++":"--";
				GmlPrint_node(r,x45,stack,0);
				r.b+="[|";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+="]";
			}
			break;
		case 74:
			r.b+="ds_map_find_value";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,2);
			r.b+=")";
			break;
		case 75:
			r.b+="ds_map_set";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,2);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,2);
			r.b+=")";
			break;
		case 76:
			var x48=_g1[3];
			if(ast_GmlNodeTools_needsAf(x48)){
				r.b+="ds_map_aop";
				r.b+="(";
				GmlPrint_node(r,x48,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[5]));
				r.b+=", ";
				GmlPrint_node(r,_g1[6],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x48,stack,0);
				r.b+="[?";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[5]));
				r.b+="= ";
				GmlPrint_node(r,_g1[6],stack,2);
			}
			break;
		case 77:
			var x49=_g1[3];
			if(ast_GmlNodeTools_needsAf(x49)){
				r.b+="ds_map_prefix";
				r.b+="(";
				GmlPrint_node(r,x49,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[5])?"++":"--";
				GmlPrint_node(r,x49,stack,0);
				r.b+="[?";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="]";
			}
			break;
		case 78:
			var x50=_g1[3];
			if(ast_GmlNodeTools_needsAf(x50)){
				r.b+="ds_map_postfix";
				r.b+="(";
				GmlPrint_node(r,x50,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				if(_g1[5]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x50,stack,0);
				r.b+="[?";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+="]";
				r.b+=(_g1[5])?"++":"--";
			}
			break;
		case 79:
			r.b+="ds_grid_get";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=")";
			break;
		case 80:
			r.b+="ds_grid_set";
			r.b+="(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=", ";
			GmlPrint_node(r,_g1[6],stack,0);
			r.b+=")";
			break;
		case 81:
			var x53=_g1[3];
			if(ast_GmlNodeTools_needsAf(x53)){
				r.b+="ds_grid_aop";
				r.b+="(";
				GmlPrint_node(r,x53,stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+=", ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toJS(_g1[6]));
				r.b+=", ";
				GmlPrint_node(r,_g1[7],stack,2);
				r.b+=")";
			}else {
				GmlPrint_node(r,x53,stack,0);
				r.b+="[#";
				GmlPrint_node(r,_g1[4],stack,2);
				r.b+=", ";
				GmlPrint_node(r,_g1[5],stack,2);
				r.b+="] ";
				r.b+=Std_string(ast__GmlOp_GmlOp_Impl__toString(_g1[6]));
				r.b+="= ";
				GmlPrint_node(r,_g1[7],stack,2);
			}
			break;
		case 82:
			var x54=_g1[3];
			if(ast_GmlNodeTools_needsAf(x54)){
				r.b+="ds_grid_prefix";
				r.b+="(";
				GmlPrint_node(r,x54,stack,2);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				r.b+=(_g1[6])?"++":"--";
				GmlPrint_node(r,x54,stack,0);
				r.b+="[#";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
			}
			break;
		case 83:
			var x55=_g1[3];
			if(ast_GmlNodeTools_needsAf(x55)){
				r.b+="ds_grid_postfix";
				r.b+="(";
				GmlPrint_node(r,x55,stack,2);
				r.b+=", ";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+=", ";
				if(_g1[6]){
					r.b+="1";
				}else r.b+="-1";
				r.b+=")";
			}else {
				GmlPrint_node(r,x55,stack,0);
				r.b+="[#";
				GmlPrint_index(r,_g1[4],stack,flags);
				r.b+=", ";
				GmlPrint_index(r,_g1[5],stack,flags);
				r.b+="]";
				r.b+=(_g1[6])?"++":"--";
			}
			break;
		case 87:
			if((flags&2)==0)r.b+="(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=" ? ";
			GmlPrint_node(r,_g1[4],stack,0);
			r.b+=" : ";
			GmlPrint_node(r,_g1[5],stack,0);
			if((flags&2)==0)r.b+=")";
			break;
		case 86:
			var o17=_g1[5];
			if(o17!=null){
				r.b+="if (";
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=") {";
				r.indent+=1;
				r.addLine();
				GmlPrint_node(r,_g1[4],stack,1);
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				r.indent-=1;
				r.addLine();
				r.b+="}";
				r.semicoAfter=r.b.length;
				r.b+=" else ";
				GmlPrint_node(r,o17,stack,0);
			}else {
				r.b+="if (";
				GmlPrint_node(r,_g1[3],stack,2);
				r.b+=") ";
				GmlPrint_node(r,_g1[4],stack,0);
			}
			break;
		case 88:
			var o18=_g1[5];
			var m6=_g1[4];
			r.b+="switch (";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=") {";
			r.indent+=1;
			n=m6.length;
			for(i=0;i<n;++i){
				var cv=m6[i].values;
				r.addLine();
				r.b+="case ";
				GmlPrint_node(r,cv[0],stack,2);
				r.b+=":";
				for(k=1;k<cv.length;++k){
					r.b+=" case ";
					GmlPrint_node(r,cv[k],stack,2);
					r.b+=":";
				}
				r.b+=" ";
				GmlPrint_node(r,m6[i].expr,stack,1);
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
			}
			if(o18!=null){
				r.addLine();
				r.b+="default: ";
				GmlPrint_node(r,o18,stack,1);
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
			}
			r.indent-=1;
			r.addLine();
			r.b+="}";
			r.semicoAfter=r.b.length;
			break;
		case 85:
			w=_g1[3];
			n=w.length;
			if(n==1){
				GmlPrint_node(r,w[0],stack,flags);
			}else if(n==0){
				if((flags&1)==0){
					r.b+="{ ";
					r.b+="}";
					r.semicoAfter=r.b.length;
				}
			}else {
				z2=(flags&1)==0;
				if(z2){
					r.b+="{";
					r.indent+=1;
					r.addLine();
				}
				z=false;
				i=0;
				while(i<n){
					if(z)r.addLine();
					k=r.b.length;
					var _g11=w[i];
					if(_g11[1]==84){
						if(_g11[4]==null){
							var name=_g11[3];
							r.b+="var ";
							r.b+=(name==null)?"null":""+name;
							while(i+1<n){
								var _g12=w[i+1];
								if(_g12[1]==84){
									var v26=_g12[4];
									var name1=_g12[3];
									if(v26==null){
										r.b+=", ";
										r.b+=(name1==null)?"null":""+name1;
										++i;
										continue;
									}
								}
								break;
							}
						}else GmlPrint_node(r,w[i],stack,5);
					}else GmlPrint_node(r,w[i],stack,5);
					z=r.b.length>k;
					if(z){
						if(r.b.length>r.semicoAfter){
							r.b+=";";
							r.semicoAfter=r.b.length;
						}
					}
					if(w[i][1]==110)z=false;
					++i;
				}
				if(z2){
					r.indent-=1;
					r.addLine();
					r.b+="}";
					r.semicoAfter=r.b.length;
				}
			}
			break;
		case 91:
			r.b+="while (";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=") ";
			GmlPrint_node(r,_g1[4],stack,0);
			break;
		case 93:
			r.b+="do ";
			GmlPrint_node(r,_g1[3],stack,0);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" while (";
			GmlPrint_node(r,_g1[4],stack,2);
			r.b+=")";
			break;
		case 92:
			r.b+="do ";
			GmlPrint_node(r,_g1[3],stack,0);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" while (";
			GmlPrint_node(r,ast_GmlNodeTools_invert(_g1[4]),stack,2);
			r.b+=")";
			break;
		case 94:
			r.b+="repeat (";
			GmlPrint_node(r,_g1[3],stack,2);
			r.b+=") ";
			GmlPrint_node(r,_g1[4],stack,0);
			break;
		case 95:
			r.b+="for (";
			GmlPrint_node(r,_g1[3],stack,0);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" ";
			GmlPrint_node(r,_g1[4],stack,2);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" ";
			GmlPrint_node(r,_g1[5],stack,0);
			r.b+=") ";
			GmlPrint_node(r,_g1[6],stack,0);
			break;
		case 96:
			q=_g1[3];
			q2=_g1[4];
			switch(q[1]){
				case 8:GmlPrint_node(r,q2,stack,flags);break;
				case 9:
					s=GmlPrint_self;
					GmlPrint_self=GmlPrint_other;
					GmlPrint_other=s;
					GmlPrint_node(r,q2,stack,flags);
					s=GmlPrint_self;
					GmlPrint_self=GmlPrint_other;
					GmlPrint_other=s;
					break;
				default:
					if((flags&1)==0){
						r.b+="{";
						r.indent+=1;
						r.addLine();
					}
					var w1=new tools_GmlBuffer();
					GmlPrint_node(w1,q,stack,2);
					GmlPrint_withDepth++;
					s=GmlPrint_other;
					GmlPrint_other=GmlPrint_self;
					GmlPrint_self="gml$self"+GmlPrint_withDepth;
					var w2=new tools_GmlBuffer();
					GmlPrint_node(w2,q2,stack,1);
					r.b+=Std_string(data_GmlAPI_withFunc(GmlPrint_withDepth,StringTools_rpad("","\t",w1.indent),"\t",w1.b,w2.b));
					GmlPrint_self=GmlPrint_other;
					GmlPrint_other=s;
					GmlPrint_withDepth--;
					if((flags&1)==0){
						r.indent-=1;
						r.addLine();
						r.b+="}";
						r.semicoAfter=r.b.length;
					}
			}
			break;
		case 97:
			r.b+="once(";
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+=")";
			break;
		case 99:
			if(GmlPrint_printScript.hasYield){
				if((flags&1)==0)r.b+="{ ";
				r.b+="l_ctx";
				r.b+="[@";
				r.b+="0/* yield */";
				r.b+="] = 0";
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				r.b+=" ";
				r.b+="l_ctx";
				r.b+="[@";
				r.b+="1/* label */";
				r.b+="] = -1";
				r.addHint("exit");
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				r.b+=" ";
				r.b+="return false";
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				if((flags&1)==0){
					r.b+=" ";
					r.b+="}";
					r.semicoAfter=r.b.length;
				}
			}else r.b+="return 0";
			break;
		case 98:
			if(GmlPrint_printScript.hasYield){
				if((flags&1)==0)r.b+="{ ";
				r.b+="l_ctx";
				r.b+="[@";
				r.b+="0/* yield */";
				r.b+="] = ";
				GmlPrint_node(r,_g1[3],stack,2);
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				r.b+=" ";
				r.b+="l_ctx";
				r.b+="[@";
				r.b+="1/* label */";
				r.b+="] = -1";
				r.addHint("exit");
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				r.b+=" ";
				r.b+="return false";
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
				if((flags&1)==0){
					r.b+=" ";
					r.b+="}";
					r.semicoAfter=r.b.length;
				}
			}else {
				r.b+="return ";
				GmlPrint_node(r,_g1[3],stack,2);
			}
			break;
		case 108:
			var s53=_g1[3];
			r.b+="//";
			r.b+=(s53==null)?"null":""+s53;
			r.semicoAfter=r.b.length;
			break;
		case 109:
			var s54=_g1[3];
			r.b+="//";
			r.b+=(s54==null)?"null":""+s54;
			r.addLine();
			GmlPrint_node(r,_g1[4],stack,flags);
			break;
		case 111:
			var s56=_g1[3];
			r.addLine();
			r.b+="//";
			r.b+=(s56==null)?"null":""+s56;
			r.addLine();
			GmlPrint_node(r,_g1[4],stack,flags);
			break;
		case 110:
			var s55=_g1[4];
			z=(flags&4)!=0;
			GmlPrint_node(r,_g1[3],stack,flags);
			if(z){
				if(r.b.length>r.semicoAfter){
					r.b+=";";
					r.semicoAfter=r.b.length;
				}
			}
			r.b+=" //";
			r.b+=(s55==null)?"null":""+s55;
			r.addLine();
			r.semicoAfter=r.b.length;
			if(!z)r.addLine();
			break;
		case 112:
			var s57=_g1[3];
			r.b+="/*";
			r.b+=(s57==null)?"null":""+s57;
			r.b+="*/";
			r.semicoAfter=r.b.length;
			break;
		case 114:
			var s59=_g1[4];
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+="/* ";
			r.b+=(s59==null)?"null":""+s59;
			r.b+=" */";
			break;
		case 113:
			var s58=_g1[3];
			r.b+="/*";
			r.b+=(s58==null)?"null":""+s58;
			r.b+="*/ ";
			GmlPrint_node(r,_g1[4],stack,0);
			break;
		case 103:
			var l=_g1[4];
			if((flags&1)==0)r.b+="{ ";
			r.b+="l_ctx";
			r.b+="[@";
			r.b+="0/* yield */";
			r.b+="] = ";
			GmlPrint_node(r,_g1[3],stack,2);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" ";
			r.b+="l_ctx";
			r.b+="[@";
			r.b+="1/* label */";
			r.b+="] = ";
			r.b+=(l==null)?"null":""+l;
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" ";
			r.b+="return true";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			if((flags&1)==0){
				r.b+=" ";
				r.b+="}";
				r.semicoAfter=r.b.length;
			}
			break;
		case 104:
			var s50=_g1[4];
			var i39=_g1[3];
			if(crWasLabel&&!GmlPrint_crReplaceMap.h[i39]){
				GmlPrint_crReplaceList.push({from:i39,to:GmlPrint_crLabelId});
				GmlPrint_crReplaceMap.h[i39]=true;
			}
			r.b+="case ";
			r.b+=(i39==null)?"null":""+i39;
			r.b+="/* ";
			r.b+=Std_string(_g1[2].toString());
			r.b+=" ";
			r.b+=(s50==null)?"null":""+s50;
			r.b+=" */:";
			r.semicoAfter=r.b.length;
			break;
		case 105:
			var i40=_g1[3];
			if((flags&1)==0)r.b+="{ ";
			if(GmlPrint_printScript.hasYield){
				r.b+="l_ctx";
				r.b+="[@";
				r.b+="1/* label */";
				r.b+="] = ";
			}else {
				r.b+="l_label";
				r.b+=" = ";
			}
			r.b+=(i40==null)?"null":""+i40;
			r.addHint(_g1[4]);
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" continue";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			if((flags&1)==0){
				r.b+=" ";
				r.b+="}";
				r.semicoAfter=r.b.length;
			}
			break;
		case 16:
			GmlPrint_node(r,_g1[3],stack,0);
			r.b+="(";
			w=_g1[4];
			n=w.length;
			for(i=0;i<n;++i){
				if(i>0)r.b+=", ";
				GmlPrint_node(r,w[i],stack,2);
			}
			r.b+=")";
			break;
		case 7:
			var s3=_g1[3];
			r.b+=(s3==null)?"null":""+s3;
			break;
		default:
			r.b+='@ERROR"Unsupported structure: ';
			r.b+=Std_string(o[0]);
			r.b+='"';
	}
	stack.shift();
}
function GmlPrint_scriptFuncBody(r,scr){
	var stack=[];
	GmlPrint_crLabelId=-1;
	GmlPrint_crReplaceList=[];
	GmlPrint_crReplaceMap=new haxe_ds_IntMap();
	var out=r;
	r=new tools_GmlBuffer();
	r.indent=out.indent;
	r.semicoAfter=r.b.length;
	GmlPrint_node(r,scr.node,stack,1);
	if(r.b.length>r.semicoAfter){
		r.b+=";";
		r.semicoAfter=r.b.length;
	}
	var rs=r.b;
	var pre=((GmlPrint_printScript.hasYield)?"l_ctx[@1/* label */]":"l_label")+" = ";
	var _g=0;
	var _g1=GmlPrint_crReplaceList;
	while(_g<_g1.length){
		var pair=_g1[_g];
		++_g;
		var v0=pre+pair.from;
		var v1=pre+pair.to;
		rs=StringTools_replace(rs,v0+";",v1+";");
		rs=StringTools_replace(rs,v0+"/*",v1+"/*");
	}
	out.b+=(rs==null)?"null":""+rs;
}
function GmlPrint_scriptFunc(r,scr){
	var _ps=GmlPrint_printScript;
	GmlPrint_printScript=scr;
	GmlPrint_self="self";
	GmlPrint_other="other";
	GmlPrint_withDepth=0;
	var scrNode=scr.node;
	var hasArgs=gmcr_CrCore_hasArgs(scrNode,null);
	var hasLabel=gmcr_CrCore_hasLabel(scrNode,null);
	var hasYield=scr.hasYield;
	r.b+="#define ";
	r.b+=Std_string(scr.name);
	r.addLine();
	if(gmcr_CrCore_v2){
		var rxArg=new EReg("^(/\\s*@(param|arg|argument)\\s+)","");
		var addCtx=hasYield;
		if(hasYield){
			var iter=null;
			iter=function(q,st){
				var _g=q;
				if(_g[1]==108){
					var s=_g[3];
					var d=_g[2];
					if(rxArg.match(s)){
						SfEnumTools_setTo(q,ast_GmlNodeDef_Block(d,[ast_GmlNodeDef_CommentLine(d,rxArg.matched(1)+"ctx"),ast_GmlNodeDef_CommentLine(d,s)]));
						return true;
					}
				}
				return ast_GmlNodeTools_seek(q,st,iter);
			}
			if(!iter(scrNode,null)){
				var d1=scrNode[2];
				var ctx=ast_GmlNodeDef_CommentLine(d1,"/ @param ctx");
				var _g1=scrNode;
				if(_g1[1]==85){
					var w=_g1[3];
					var d2=_g1[2];
					w.unshift(ctx);
				}else {
					scrNode=ast_GmlNodeDef_Block(d1,[ctx,scrNode]);
					scr.node=scrNode;
				}
			}
		}
	}else {
		var _g2=scrNode;
		if(_g2[1]==85){
			var w1=_g2[3];
			if(w1.length>0){
				var _g3=w1[0];
				if(_g3[1]==108){
					var s1=_g3[3];
					var d3=_g3[2];
					if(hasYield)s1=new EReg("^(/\\s*\\w+\\()([^\\)]*)","").map(s1,function(rx){
						var s2=rx.matched(2);
						if(s2!="")s2=", "+s2;
						return rx.matched(1)+"ctx"+s2;
					});
					r.b+="//";
					r.b+=(s1==null)?"null":""+s1;
					r.addLine();
					w1.shift();
				}
			}
		}
	}
	if(hasYield){
		r.b+="var ";
		r.b+="l_ctx";
		r.b+=" = argument[0]";
		if(r.b.length>r.semicoAfter){
			r.b+=";";
			r.semicoAfter=r.b.length;
		}
		r.addLine();
		r.b+="if (!is_array(";
		r.b+="l_ctx";
		r.b+=")) ";
		if(hasArgs){
			r.b+="{";
			r.indent+=1;
			r.addLine();
			r.b+="l_ctx";
			r.b+=" = array_create(";
			r.b+=Std_string(scr.locals+3);
			r.b+=")";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="var l_argc = argument_count - 1";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="var l_args = array_create(l_argc)";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="while (--l_argc >= 0) l_args[@l_argc] = argument[l_argc + 1]";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="l_ctx";
			r.b+="[";
			r.b+="2/* args */";
			r.b+="] = ";
			r.b+="l_args";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="return ";
			r.b+="l_ctx";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.indent-=1;
			r.addLine();
			r.b+="}";
			r.semicoAfter=r.b.length;
			r.addLine();
		}else {
			r.b+="return array_create(";
			r.b+=Std_string(scr.locals+3);
			r.b+=")";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
		}
		if(hasArgs){
			r.b+="var ";
			r.b+="l_args";
			r.b+=" = ";
			r.b+="l_ctx";
			r.b+="[";
			r.b+="2/* args */";
			r.b+="]";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
		}
	}
	if(hasLabel){
		if(hasYield){
			r.b+="while (true) switch (";
			r.b+="l_ctx";
			r.b+="[";
			r.b+="1/* label */";
			r.b+="]) {";
			r.indent+=1;
			r.addLine();
		}else {
			r.b+="var ";
			r.b+="l_label";
			r.b+=" = 0";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.addLine();
			r.b+="while (true) switch (";
			r.b+="l_label";
			r.b+=") {";
			r.indent+=1;
			r.addLine();
		}
		r.b+="case 0";
		r.addHint(scr.node[2].toString()+" begin");
		r.b+=":";
		r.addLine();
	}
	GmlPrint_scriptFuncBody(r,scr);
	if(hasLabel){
		r.addLine();
		r.b+="default";
		r.addHint(scr.source.eof.toString()+" end");
		r.b+=": ";
		if(hasYield){
			r.b+="l_ctx";
			r.b+="[@";
			r.b+="0/* yield */";
			r.b+="] = 0";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
			r.b+=" return false";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
		}else {
			r.b+="exit";
			if(r.b.length>r.semicoAfter){
				r.b+=";";
				r.semicoAfter=r.b.length;
			}
		}
		r.indent-=1;
		r.addLine();
		r.b+="}";
		r.semicoAfter=r.b.length;
	}
	GmlPrint_printScript=_ps;
}
function GmlPrint_program(pg){
	var _pg=GmlPrint_printProgram;
	GmlPrint_printProgram=pg;
	var r=new tools_GmlBuffer();
	var i;
	var scripts=pg.scripts;
	for(i=0;i<scripts.length;++i){
		GmlPrint_scriptFunc(r,scripts[i]);
		r.addLine();
	}
	var s=r.b;
	s=StringTools_replace(s,"\n\tcase","\ncase");
	s=StringTools_replace(s,"\n\tdefault","\ndefault");
	s=StringTools_replace(s,"\t","    ");
	s=StringTools_replace(s,"#define main\r\n","");
	s=s.replace(new RegExp(" \\*/:\r\ncase \\d+/\\* ","g".split("u").join("")),", ");
	s=s.replace(new RegExp("case \\d+/\\*(.+?) \\*/:\r\ndefault/\\* ","g".split("u").join("")),"default/*$1, ");
	GmlPrint_printProgram=_pg;
	return s;
}
function GmlProgram(sources){
	this.isReady=false;
	this.errorText=null;
	this.macros=Object.create(null);
	this.enumMap=Object.create(null);
	this.enums=[];
	this.scriptMap=Object.create(null);
	this.scripts=[];
	this.sources=null;
	this.sources=sources;
	var builders=[];
	var _g=0;
	while(_g<sources.length){
		var src=sources[_g];
		++_g;
		var b=new GmlBuilder(src);
		builders.push(b);
		if(b.errorText==null){
			var main=src.main;
			var _g1=0;
			var _g2=b.scripts;
			while(_g1<_g2.length){
				var scr=_g2[_g1];
				++_g1;
				if(this.scriptMap[scr.name]!=null){
					if(scr.name==main){
						var _g3=this.scriptMap[main].node;
						if(_g3[1]==85&&_g3[3].length==0){
							HxOverrides_remove(this.scripts,this.scriptMap[main]);
							this.scripts.push(scr);
							this.scriptMap[scr.name]=scr;
						}else {
							this.error('Cannot override prefix-script "'+main+'" because it is not empty',scr.pos);
							return;
						}
					}else {
						this.error("Script "+scr.name+" is already defined at "+this.scriptMap[scr.name].pos.toString(),scr.pos);
						return;
					}
				}else {
					this.scripts.push(scr);
					this.scriptMap[scr.name]=scr;
				}
			}
			var _g11=0;
			var _g21=b.enums;
			while(_g11<_g21.length){
				var e=_g21[_g11];
				++_g11;
				this.enums.push(e);
				this.enumMap[e.name]=e;
			}
			var mcrNames=b.macroNames;
			var mcrNodes=b.macroNodes;
			var mcrMap=this.macros;
			var i=0;
			for(var _g12=mcrNames.length;i<_g12;i++)mcrMap[mcrNames[i]]=mcrNodes[i];
		}else {
			this.errorText=b.errorText;
			this.errorPos=b.errorPos;
			return;
		}
	}
	var i1;
	var n=this.scripts.length;
	for(i1=0;i1<n;++i1)this.scripts[i1].index=i1;
	if(this.check()){
		GmlProgram_seekInst=null;
		return;
	}
	this.isReady=true;
}
GmlProgram.prototype={
	error:function(text,d){
		var pos=d;
		this.errorText=pos.toString()+" "+text;
		this.errorPos=pos;
		return true;
	},
	seek:function(f,st){
		if(st==null)st=false;
		var w;
		if(st){
			w=[];
		}else w=null;
		GmlProgram_seekFunc=f;
		var m=this.scripts;
		var n=m.length;
		var i=0;
		while(i<n){
			var scr=m[i];
			GmlProgram_seekScript=scr;
			var scrNode=scr.node;
			if(scrNode!=null&&f(scrNode,w)){
				break;
			}else ++i;
		}
		GmlProgram_seekScript=null;
		GmlProgram_seekFunc=null;
		var st1=st;
		return i<n;
	},
	check:function(){
		GmlProgram_seekInst=this;
		if(this.seek(gml_SeekArguments_proc,false))return true;
		if(this.seek(gml_SeekLocals_proc,false))return true;
		if(this.seek(gml_SeekIdents_proc,true))return true;
		if(this.seek(gml_SeekFields_proc,false))return true;
		if(gml_SeekEnumValues_proc())return true;
		if(this.seek(gml_SeekEnumFields_proc,false))return true;
		if(this.seek(gml_SeekRepeat_proc,true))return true;
		if(gml_SeekEval_opt())return true;
		if(this.seek(gml_SeekAdjfix_proc,true))return true;
		if(this.seek(gml_SeekSetOp_proc,true))return true;
		if(this.seek(gml_SeekMergeBlocks_proc,true))return true;
		if(gmcr_CrCore_seek(this))return true;
		GmlProgram_seekInst=null;
		return false;
	}
}
function HxOverrides_cca(s,index){
	var x=s.charCodeAt(index);
	if(x!=x)return undefined;
	return x;
}
function HxOverrides_substr(s,pos,len){
	if(len==null){
		len=s.length;
	}else if(len<0){
		if(pos==0){
			len=s.length+len;
		}else return "";
	}
	return s.substr(pos,len);
}
function HxOverrides_remove(a,obj){
	var i=a.indexOf(obj);
	if(i==-1)return false;
	a.splice(i,1);
	return true;
}
function SfEnumTools_setTo(q,v){
	var qx=q;
	var vx=v;
	var qn=qx.length;
	var vn=vx.length;
	if(qn>vn)qx.splice(vn,qn-vn);
	var i=0;
	for(var _g=vn;i<_g;i++)qx[i]=vx[i];
}
function Std_string(s){
	return js_Boot___string_rec(s,"");
}
function Std_parseInt(x){
	var i=parseInt(x,10);
	if(i==0){
		var c1=HxOverrides_cca(x,1);
		if(c1==120||c1==88)i=parseInt(x);
	}
	if(isNaN(i))return null;
	return i;
}
function StringBuf(){
	this.b="";
}
function StringTools_startsWith(s,start){
	return s.length>=start.length&&HxOverrides_substr(s,0,start.length)==start;
}
function StringTools_rpad(s,c,l){
	if(c.length<=0)return s;
	while(s.length<l){
		s+=c;
	}
	return s;
}
function StringTools_replace(s,sub,by){
	return s.split(sub).join(by);
}
function ast_GmlEnum(name,pos){
	this.ctrMap=Object.create(null);
	this.ctrList=[];
	this.name=name;
	this.pos=pos;
}
function ast_GmlEnumCtr(name,pos,node){
	this.name=name;
	this.pos=pos;
	this.node=node;
}
var ast_GmlNodeDef={__ename__:true}
function ast_GmlNodeDef_Undefined(d){
	var r=["Undefined",0,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Number(d,value,src){
	var r=["Number",1,d,value,src];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CString(d,value){
	var r=["CString",2,d,value];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnumCtr(d,e,ctr){
	var r=["EnumCtr",3,d,e,ctr];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ArrayDecl(d,values){
	var r=["ArrayDecl",4,d,values];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ObjectDecl(d,keys,values){
	var r=["ObjectDecl",5,d,keys,values];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnsureArray(d,expr){
	var r=["EnsureArray",6,d,expr];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Ident(d,id){
	var r=["Ident",7,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Self(d){
	var r=["Self",8,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Other(d){
	var r=["Other",9,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_GlobalRef(d){
	var r=["GlobalRef",10,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Script(d,ref){
	var r=["Script",11,d,ref];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Const(d,id){
	var r=["Const",12,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ArgConst(d,id){
	var r=["ArgConst",13,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ArgIndex(d,id){
	var r=["ArgIndex",14,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ArgCount(d){
	var r=["ArgCount",15,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Call(d,x,args){
	var r=["Call",16,d,x,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallScript(d,name,args){
	var r=["CallScript",17,d,name,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallScriptAt(d,inst,script,args){
	var r=["CallScriptAt",18,d,inst,script,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallScriptId(d,index,args){
	var r=["CallScriptId",19,d,index,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallField(d,inst,prop,args){
	var r=["CallField",20,d,inst,prop,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallFunc(d,s,args){
	var r=["CallFunc",21,d,s,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CallFuncAt(d,x,s,args){
	var r=["CallFuncAt",22,d,x,s,args];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Prefix(d,x,inc){
	var r=["Prefix",23,d,x,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Postfix(d,x,inc){
	var r=["Postfix",24,d,x,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_UnOp(d,x,o){
	var r=["UnOp",25,d,x,o];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_BinOp(d,o,a,b){
	var r=["BinOp",26,d,o,a,b];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_SetOp(d,o,a,b){
	var r=["SetOp",27,d,o,a,b];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_ToBool(d,v){
	var r=["ToBool",28,d,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_FromBool(d,v){
	var r=["FromBool",29,d,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_In(d,fd,val,not){
	var r=["In",30,d,fd,val,not];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Local(d,id){
	var r=["Local",31,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_LocalSet(d,id,val){
	var r=["LocalSet",32,d,id,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_LocalAop(d,id,op,val){
	var r=["LocalAop",33,d,id,op,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Global(d,id){
	var r=["Global",34,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_GlobalSet(d,id,val){
	var r=["GlobalSet",35,d,id,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_GlobalAop(d,id,op,val){
	var r=["GlobalAop",36,d,id,op,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Field(d,x,fd){
	var r=["Field",37,d,x,fd];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_FieldSet(d,x,fd,val){
	var r=["FieldSet",38,d,x,fd,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_FieldAop(d,x,fd,op,val){
	var r=["FieldAop",39,d,x,fd,op,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Env(d,id){
	var r=["Env",40,d,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnvSet(d,id,val){
	var r=["EnvSet",41,d,id,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnvAop(d,id,op,val){
	var r=["EnvAop",42,d,id,op,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnvFd(d,x,fd){
	var r=["EnvFd",43,d,x,fd];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnvFdSet(d,x,fd,v){
	var r=["EnvFdSet",44,d,x,fd,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_EnvFdAop(d,x,fd,op,v){
	var r=["EnvFdAop",45,d,x,fd,op,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Env1d(d,id,k){
	var r=["Env1d",46,d,id,k];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Env1dSet(d,id,k,val){
	var r=["Env1dSet",47,d,id,k,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Env1dAop(d,id,k,op,val){
	var r=["Env1dAop",48,d,id,k,op,val];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index(d,x,id){
	var r=["Index",49,d,x,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_IndexSet(d,x,id,v){
	var r=["IndexSet",50,d,x,id,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_IndexAop(d,x,id,o,v){
	var r=["IndexAop",51,d,x,id,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_IndexPrefix(d,x,i,inc){
	var r=["IndexPrefix",52,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_IndexPostfix(d,x,i,inc){
	var r=["IndexPostfix",53,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index2d(d,x,i1,i2){
	var r=["Index2d",54,d,x,i1,i2];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index2dSet(d,x,i1,i2,v){
	var r=["Index2dSet",55,d,x,i1,i2,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index2dAop(d,x,i1,i2,o,v){
	var r=["Index2dAop",56,d,x,i1,i2,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index2dPrefix(d,x,i,k,inc){
	var r=["Index2dPrefix",57,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Index2dPostfix(d,x,i,k,inc){
	var r=["Index2dPostfix",58,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId(d,x,id){
	var r=["RawId",59,d,x,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawIdSet(d,x,id,v){
	var r=["RawIdSet",60,d,x,id,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawIdAop(d,x,id,o,v){
	var r=["RawIdAop",61,d,x,id,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawIdPrefix(d,x,i,inc){
	var r=["RawIdPrefix",62,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawIdPostfix(d,x,i,inc){
	var r=["RawIdPostfix",63,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId2d(d,x,i1,i2){
	var r=["RawId2d",64,d,x,i1,i2];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId2dSet(d,x,i1,i2,v){
	var r=["RawId2dSet",65,d,x,i1,i2,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId2dAop(d,x,i1,i2,o,v){
	var r=["RawId2dAop",66,d,x,i1,i2,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId2dPrefix(d,x,i,k,inc){
	var r=["RawId2dPrefix",67,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_RawId2dPostfix(d,x,i,k,inc){
	var r=["RawId2dPostfix",68,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsList(d,lx,id){
	var r=["DsList",69,d,lx,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsListSet(d,lx,id,v){
	var r=["DsListSet",70,d,lx,id,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsListAop(d,lx,id,o,v){
	var r=["DsListAop",71,d,lx,id,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsListPrefix(d,x,i,inc){
	var r=["DsListPrefix",72,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsListPostfix(d,x,i,inc){
	var r=["DsListPostfix",73,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsMap(d,lx,id){
	var r=["DsMap",74,d,lx,id];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsMapSet(d,lx,id,v){
	var r=["DsMapSet",75,d,lx,id,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsMapAop(d,lx,id,o,v){
	var r=["DsMapAop",76,d,lx,id,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsMapPrefix(d,x,i,inc){
	var r=["DsMapPrefix",77,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsMapPostfix(d,x,i,inc){
	var r=["DsMapPostfix",78,d,x,i,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsGrid(d,lx,i1,i2){
	var r=["DsGrid",79,d,lx,i1,i2];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsGridSet(d,lx,i1,i2,v){
	var r=["DsGridSet",80,d,lx,i1,i2,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsGridAop(d,lx,i1,i2,o,v){
	var r=["DsGridAop",81,d,lx,i1,i2,o,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsGridPrefix(d,x,i,k,inc){
	var r=["DsGridPrefix",82,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DsGridPostfix(d,x,i,k,inc){
	var r=["DsGridPostfix",83,d,x,i,k,inc];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_VarDecl(d,name,value){
	var r=["VarDecl",84,d,name,value];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Block(d,nodes){
	var r=["Block",85,d,nodes];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_IfThen(d,cond,then,not){
	var r=["IfThen",86,d,cond,then,not];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Ternary(d,cond,then,not){
	var r=["Ternary",87,d,cond,then,not];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Switch(d,expr,list,def){
	var r=["Switch",88,d,expr,list,def];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Wait(d,time){
	var r=["Wait",89,d,time];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Fork(d){
	var r=["Fork",90,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_While(d,cond,node){
	var r=["While",91,d,cond,node];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DoUntil(d,node,cond){
	var r=["DoUntil",92,d,node,cond];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_DoWhile(d,node,cond){
	var r=["DoWhile",93,d,node,cond];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Repeat(d,times,node){
	var r=["Repeat",94,d,times,node];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_For(d,pre,cond,post,loop){
	var r=["For",95,d,pre,cond,post,loop];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_With(d,ctx,node){
	var r=["With",96,d,ctx,node];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Once(d,node){
	var r=["Once",97,d,node];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Return(d,v){
	var r=["Return",98,d,v];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Exit(d){
	var r=["Exit",99,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Break(d){
	var r=["Break",100,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Continue(d){
	var r=["Continue",101,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Debugger(d){
	var r=["Debugger",102,d];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Yield(d,v,i){
	var r=["Yield",103,d,v,i];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Label(d,i,name){
	var r=["Label",104,d,i,name];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_Jump(d,i,name){
	var r=["Jump",105,d,i,name];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_UserLabel(d,s){
	var r=["UserLabel",106,d,s];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_UserJump(d,s){
	var r=["UserJump",107,d,s];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentLine(d,s){
	var r=["CommentLine",108,d,s];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentLinePre(d,s,x){
	var r=["CommentLinePre",109,d,s,x];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentLinePost(d,x,s){
	var r=["CommentLinePost",110,d,x,s];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentLineSep(d,s,x){
	var r=["CommentLineSep",111,d,s,x];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentBlock(d,s){
	var r=["CommentBlock",112,d,s];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentBlockPre(d,s,x,pl){
	var r=["CommentBlockPre",113,d,s,x,pl];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeDef_CommentBlockPost(d,x,s,pl){
	var r=["CommentBlockPost",114,d,x,s,pl];
	r.__enum__=ast_GmlNodeDef;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlNodeTools_unpack(q){
	while(q!=null){
		var _g=q;
		if(_g[1]==85){
			if(_g[3].length==1){
				q=_g[3][0];
			}else return q;
		}else return q;
	}
	return q;
}
function ast_GmlNodeTools_isSimple(q){
	var i, n, w;
	var _g=q;
	switch(_g[1]){
		case 1:return true;
		case 2:return true;
		case 0:return true;
		case 31:return true;
		case 34:return true;
		case 4:
			w=_g[3];
			n=w.length;
			i=0;
			while(i<n){
				if(ast_GmlNodeTools_isSimple(w[i])){
					++i;
				}else break;
			}
			return i>=n;
		case 5:
			w=_g[4];
			n=w.length;
			i=0;
			while(i<n){
				if(ast_GmlNodeTools_isSimple(w[i])){
					++i;
				}else break;
			}
			return i>=n;
		case 8:return true;
		case 9:return true;
		case 37:return ast_GmlNodeTools_isSimple(_g[3]);
		case 49:return ast_GmlNodeTools_isSimple(_g[3])&&ast_GmlNodeTools_isSimple(_g[4]);
		default:return false;
	}
}
function ast_GmlNodeTools_isStatement(q){
	switch(q[1]){
		case 16:return true;
		case 27:return true;
		case 84:return true;
		case 23:return true;
		case 24:return true;
		default:return false;
	}
}
function ast_GmlNodeTools_isInBlock(q,p){
	if(p==null)return false;
	var _g=p;
	switch(_g[1]){
		case 85:return true;
		case 86:return q!=_g[3];
		case 91:return q!=_g[3];
		case 93:return q!=_g[4];
		case 92:return q!=_g[4];
		case 94:return q!=_g[3];
		case 95:return q!=_g[4];
		case 88:return q!=_g[3];
		default:return false;
	}
}
function ast_GmlNodeTools_needsAf(q){
	var _g=q;
	switch(_g[1]){
		case 31:return false;
		case 34:return false;
		case 12:return false;
		case 40:return false;
		case 43:return false;
		case 37:return false;
		case 7:return false;
		case 113:return ast_GmlNodeTools_needsAf(_g[4]);
		case 114:return ast_GmlNodeTools_needsAf(_g[3]);
		default:return true;
	}
}
function ast_GmlNodeTools_offset(q,i){
	var d=q[2];
	var _g=q;
	if(_g[1]==1)return ast_GmlNodeDef_Number(_g[2],_g[3]+i,null);
	if(i<0){
		return ast_GmlNodeDef_BinOp(d,17,ast_GmlNodeTools_clone(q),ast_GmlNodeDef_Number(d, -i,null));
	}else return ast_GmlNodeDef_BinOp(d,16,ast_GmlNodeTools_clone(q),ast_GmlNodeDef_Number(d,i,null));
}
function ast_GmlNodeTools_invert(q){
	var _g=q;
	switch(_g[1]){
		case 1:
			switch(_g[3]){
				case 1:return ast_GmlNodeDef_Number(_g[2],0,null);
				case 0:return ast_GmlNodeDef_Number(_g[2],1,null);
			}
			break;
		case 26:
			switch(_g[3]){
				case 68:return ast_GmlNodeDef_BinOp(_g[2],67,_g[4],_g[5]);
				case 69:return ast_GmlNodeDef_BinOp(_g[2],66,_g[4],_g[5]);
				case 66:return ast_GmlNodeDef_BinOp(_g[2],69,_g[4],_g[5]);
				case 67:return ast_GmlNodeDef_BinOp(_g[2],68,_g[4],_g[5]);
				case 64:return ast_GmlNodeDef_BinOp(_g[2],65,_g[4],_g[5]);
				case 65:return ast_GmlNodeDef_BinOp(_g[2],64,_g[4],_g[5]);
			}
			break;
	}
	return ast_GmlNodeDef_UnOp(q[2],ast_GmlNodeTools_clone(q),1);
}
function ast_GmlNodeTools_equalsList(a,b){
	var n=a.length;
	if(b.length!=n)return false;
	var i=0;
	while(i<n){
		if(ast_GmlNodeTools_equals(a[i],b[i])){
			++i;
		}else return false;
	}
	return true;
}
function ast_GmlNodeTools_equals(a,b){
	if(a[1]!=b[1])return false;
	var i, n;
	var _g=a;
	switch(_g[1]){
		case 8:return true;
		case 10:return true;
		case 9:return true;
		case 101:return true;
		case 15:return true;
		case 90:return true;
		case 100:return true;
		case 0:return true;
		case 99:return true;
		case 102:return true;
		case 12:
			var _g9=b;
			if(_g9[1]==12){
				return _g[3]==_g9[3];
			}else return false;
		case 11:
			var _g8=b;
			if(_g8[1]==11){
				return _g[3]==_g8[3];
			}else return false;
		case 31:
			var _g27=b;
			if(_g27[1]==31){
				return _g[3]==_g27[3];
			}else return false;
		case 3:
			var _g3=b;
			if(_g3[1]==3){
				var b_ctr=_g3[4];
				return _g[3]==_g3[3]&&_g[4]==b_ctr;
			}else return false;
		case 2:
			var _g2=b;
			if(_g2[1]==2){
				return _g[3]==_g2[3];
			}else return false;
		case 25:
			var _g21=b;
			if(_g21[1]==25){
				var b_o=_g21[4];
				return ast_GmlNodeTools_equals(_g[3],_g21[3])&&_g[4]==b_o;
			}else return false;
		case 22:
			var _g18=b;
			if(_g18[1]==22){
				var b_args6=_g18[5];
				var b_s1=_g18[4];
				return ast_GmlNodeTools_equals(_g[3],_g18[3])&&_g[4]==b_s1&&ast_GmlNodeTools_equalsList(_g[5],b_args6);
			}else return false;
		case 7:
			var _g7=b;
			if(_g7[1]==7){
				return _g[3]==_g7[3];
			}else return false;
		case 67:
			var _g63=b;
			if(_g63[1]==67){
				var b_inc8=_g63[6];
				var b_k5=_g63[5];
				var b_i7=_g63[4];
				return ast_GmlNodeTools_equals(_g[3],_g63[3])&&ast_GmlNodeTools_equals(_g[4],b_i7)&&ast_GmlNodeTools_equals(_g[5],b_k5)&&_g[6]==b_inc8;
			}else return false;
		case 23:
			var _g19=b;
			if(_g19[1]==23){
				var b_inc=_g19[4];
				return ast_GmlNodeTools_equals(_g[3],_g19[3])&&_g[4]==b_inc;
			}else return false;
		case 24:
			var _g20=b;
			if(_g20[1]==24){
				var b_inc1=_g20[4];
				return ast_GmlNodeTools_equals(_g[3],_g20[3])&&_g[4]==b_inc1;
			}else return false;
		case 76:
			var _g72=b;
			if(_g72[1]==76){
				var b_v15=_g72[6];
				var b_o8=_g72[5];
				var b_id27=_g72[4];
				return ast_GmlNodeTools_equals(_g[3],_g72[3])&&ast_GmlNodeTools_equals(_g[4],b_id27)&&_g[5]==b_o8&&ast_GmlNodeTools_equals(_g[6],b_v15);
			}else return false;
		case 26:
			var _g22=b;
			if(_g22[1]==26){
				var b_b=_g22[5];
				var b_a=_g22[4];
				return _g[3]==_g22[3]&&ast_GmlNodeTools_equals(_g[4],b_a)&&ast_GmlNodeTools_equals(_g[5],b_b);
			}else return false;
		case 27:
			var _g23=b;
			if(_g23[1]==27){
				var b_b1=_g23[5];
				var b_a1=_g23[4];
				return _g[3]==_g23[3]&&ast_GmlNodeTools_equals(_g[4],b_a1)&&ast_GmlNodeTools_equals(_g[5],b_b1);
			}else return false;
		case 28:
			var _g24=b;
			if(_g24[1]==28){
				return ast_GmlNodeTools_equals(_g[3],_g24[3]);
			}else return false;
		case 29:
			var _g25=b;
			if(_g25[1]==29){
				return ast_GmlNodeTools_equals(_g[3],_g25[3]);
			}else return false;
		case 30:
			var _g26=b;
			if(_g26[1]==30){
				var b_not=_g26[5];
				var b_val=_g26[4];
				return ast_GmlNodeTools_equals(_g[3],_g26[3])&&ast_GmlNodeTools_equals(_g[4],b_val)&&_g[5]==b_not;
			}else return false;
		case 94:
			var _g89=b;
			if(_g89[1]==94){
				var b_node3=_g89[4];
				return ast_GmlNodeTools_equals(_g[3],_g89[3])&&ast_GmlNodeTools_equals(_g[4],b_node3);
			}else return false;
		case 32:
			var _g28=b;
			if(_g28[1]==32){
				var b_val1=_g28[4];
				return _g[3]==_g28[3]&&ast_GmlNodeTools_equals(_g[4],b_val1);
			}else return false;
		case 33:
			var _g29=b;
			if(_g29[1]==33){
				var b_val2=_g29[5];
				var b_op=_g29[4];
				return _g[3]==_g29[3]&&_g[4]==b_op&&ast_GmlNodeTools_equals(_g[5],b_val2);
			}else return false;
		case 34:
			var _g30=b;
			if(_g30[1]==34){
				return _g[3]==_g30[3];
			}else return false;
		case 35:
			var _g31=b;
			if(_g31[1]==35){
				var b_val3=_g31[4];
				return _g[3]==_g31[3]&&ast_GmlNodeTools_equals(_g[4],b_val3);
			}else return false;
		case 36:
			var _g32=b;
			if(_g32[1]==36){
				var b_val4=_g32[5];
				var b_op1=_g32[4];
				return _g[3]==_g32[3]&&_g[4]==b_op1&&ast_GmlNodeTools_equals(_g[5],b_val4);
			}else return false;
		case 37:
			var _g33=b;
			if(_g33[1]==37){
				var b_fd1=_g33[4];
				return ast_GmlNodeTools_equals(_g[3],_g33[3])&&_g[4]==b_fd1;
			}else return false;
		case 38:
			var _g34=b;
			if(_g34[1]==38){
				var b_val5=_g34[5];
				var b_fd2=_g34[4];
				return ast_GmlNodeTools_equals(_g[3],_g34[3])&&_g[4]==b_fd2&&ast_GmlNodeTools_equals(_g[5],b_val5);
			}else return false;
		case 39:
			var _g35=b;
			if(_g35[1]==39){
				var b_val6=_g35[6];
				var b_op2=_g35[5];
				var b_fd3=_g35[4];
				return ast_GmlNodeTools_equals(_g[3],_g35[3])&&_g[4]==b_fd3&&_g[5]==b_op2&&ast_GmlNodeTools_equals(_g[6],b_val6);
			}else return false;
		case 21:
			var _g17=b;
			if(_g17[1]==21){
				var b_args5=_g17[4];
				return _g[3]==_g17[3]&&ast_GmlNodeTools_equalsList(_g[4],b_args5);
			}else return false;
		case 20:
			var _g16=b;
			if(_g16[1]==20){
				var b_args4=_g16[5];
				var b_prop=_g16[4];
				return ast_GmlNodeTools_equals(_g[3],_g16[3])&&_g[4]==b_prop&&ast_GmlNodeTools_equalsList(_g[5],b_args4);
			}else return false;
		case 19:
			var _g15=b;
			if(_g15[1]==19){
				var b_args3=_g15[4];
				return ast_GmlNodeTools_equals(_g[3],_g15[3])&&ast_GmlNodeTools_equalsList(_g[4],b_args3);
			}else return false;
		case 6:
			var _g6=b;
			if(_g6[1]==6){
				return ast_GmlNodeTools_equals(_g[3],_g6[3]);
			}else return false;
		case 18:
			var _g14=b;
			if(_g14[1]==18){
				var b_args2=_g14[5];
				var b_script=_g14[4];
				return ast_GmlNodeTools_equals(_g[3],_g14[3])&&_g[4]==b_script&&ast_GmlNodeTools_equalsList(_g[5],b_args2);
			}else return false;
		case 17:
			var _g13=b;
			if(_g13[1]==17){
				var b_args1=_g13[4];
				return _g[3]==_g13[3]&&ast_GmlNodeTools_equalsList(_g[4],b_args1);
			}else return false;
		case 16:
			var _g12=b;
			if(_g12[1]==16){
				var b_args=_g12[4];
				return ast_GmlNodeTools_equals(_g[3],_g12[3])&&ast_GmlNodeTools_equalsList(_g[4],b_args);
			}else return false;
		case 1:
			var _g1=b;
			if(_g1[1]==1){
				var b_src=_g1[4];
				return _g[3]==_g1[3]&&_g[4]==b_src;
			}else return false;
		case 49:
			var _g45=b;
			if(_g45[1]==49){
				var b_id16=_g45[4];
				return ast_GmlNodeTools_equals(_g[3],_g45[3])&&ast_GmlNodeTools_equals(_g[4],b_id16);
			}else return false;
		case 50:
			var _g46=b;
			if(_g46[1]==50){
				var b_v4=_g46[5];
				var b_id17=_g46[4];
				return ast_GmlNodeTools_equals(_g[3],_g46[3])&&ast_GmlNodeTools_equals(_g[4],b_id17)&&ast_GmlNodeTools_equals(_g[5],b_v4);
			}else return false;
		case 51:
			var _g47=b;
			if(_g47[1]==51){
				var b_v5=_g47[6];
				var b_o3=_g47[5];
				var b_id18=_g47[4];
				return ast_GmlNodeTools_equals(_g[3],_g47[3])&&ast_GmlNodeTools_equals(_g[4],b_id18)&&_g[5]==b_o3&&ast_GmlNodeTools_equals(_g[6],b_v5);
			}else return false;
		case 52:
			var _g48=b;
			if(_g48[1]==52){
				var b_inc2=_g48[5];
				var b_i=_g48[4];
				return ast_GmlNodeTools_equals(_g[3],_g48[3])&&ast_GmlNodeTools_equals(_g[4],b_i)&&_g[5]==b_inc2;
			}else return false;
		case 53:
			var _g49=b;
			if(_g49[1]==53){
				var b_inc3=_g49[5];
				var b_i1=_g49[4];
				return ast_GmlNodeTools_equals(_g[3],_g49[3])&&ast_GmlNodeTools_equals(_g[4],b_i1)&&_g[5]==b_inc3;
			}else return false;
		case 54:
			var _g50=b;
			if(_g50[1]==54){
				var b_i2=_g50[5];
				var b_i11=_g50[4];
				return ast_GmlNodeTools_equals(_g[3],_g50[3])&&ast_GmlNodeTools_equals(_g[4],b_i11)&&ast_GmlNodeTools_equals(_g[5],b_i2);
			}else return false;
		case 55:
			var _g51=b;
			if(_g51[1]==55){
				var b_v6=_g51[6];
				var b_i21=_g51[5];
				var b_i12=_g51[4];
				return ast_GmlNodeTools_equals(_g[3],_g51[3])&&ast_GmlNodeTools_equals(_g[4],b_i12)&&ast_GmlNodeTools_equals(_g[5],b_i21)&&ast_GmlNodeTools_equals(_g[6],b_v6);
			}else return false;
		case 56:
			var _g52=b;
			if(_g52[1]==56){
				var b_v7=_g52[7];
				var b_o4=_g52[6];
				var b_i22=_g52[5];
				var b_i13=_g52[4];
				return ast_GmlNodeTools_equals(_g[3],_g52[3])&&ast_GmlNodeTools_equals(_g[4],b_i13)&&ast_GmlNodeTools_equals(_g[5],b_i22)&&_g[6]==b_o4&&ast_GmlNodeTools_equals(_g[7],b_v7);
			}else return false;
		case 57:
			var _g53=b;
			if(_g53[1]==57){
				var b_inc4=_g53[6];
				var b_k3=_g53[5];
				var b_i3=_g53[4];
				return ast_GmlNodeTools_equals(_g[3],_g53[3])&&ast_GmlNodeTools_equals(_g[4],b_i3)&&ast_GmlNodeTools_equals(_g[5],b_k3)&&_g[6]==b_inc4;
			}else return false;
		case 58:
			var _g54=b;
			if(_g54[1]==58){
				var b_inc5=_g54[6];
				var b_k4=_g54[5];
				var b_i4=_g54[4];
				return ast_GmlNodeTools_equals(_g[3],_g54[3])&&ast_GmlNodeTools_equals(_g[4],b_i4)&&ast_GmlNodeTools_equals(_g[5],b_k4)&&_g[6]==b_inc5;
			}else return false;
		case 59:
			var _g55=b;
			if(_g55[1]==59){
				var b_id19=_g55[4];
				return ast_GmlNodeTools_equals(_g[3],_g55[3])&&ast_GmlNodeTools_equals(_g[4],b_id19);
			}else return false;
		case 60:
			var _g56=b;
			if(_g56[1]==60){
				var b_v8=_g56[5];
				var b_id20=_g56[4];
				return ast_GmlNodeTools_equals(_g[3],_g56[3])&&ast_GmlNodeTools_equals(_g[4],b_id20)&&ast_GmlNodeTools_equals(_g[5],b_v8);
			}else return false;
		case 61:
			var _g57=b;
			if(_g57[1]==61){
				var b_v9=_g57[6];
				var b_o5=_g57[5];
				var b_id21=_g57[4];
				return ast_GmlNodeTools_equals(_g[3],_g57[3])&&ast_GmlNodeTools_equals(_g[4],b_id21)&&_g[5]==b_o5&&ast_GmlNodeTools_equals(_g[6],b_v9);
			}else return false;
		case 62:
			var _g58=b;
			if(_g58[1]==62){
				var b_inc6=_g58[5];
				var b_i5=_g58[4];
				return ast_GmlNodeTools_equals(_g[3],_g58[3])&&ast_GmlNodeTools_equals(_g[4],b_i5)&&_g[5]==b_inc6;
			}else return false;
		case 63:
			var _g59=b;
			if(_g59[1]==63){
				var b_inc7=_g59[5];
				var b_i6=_g59[4];
				return ast_GmlNodeTools_equals(_g[3],_g59[3])&&ast_GmlNodeTools_equals(_g[4],b_i6)&&_g[5]==b_inc7;
			}else return false;
		case 64:
			var _g60=b;
			if(_g60[1]==64){
				var b_i23=_g60[5];
				var b_i14=_g60[4];
				return ast_GmlNodeTools_equals(_g[3],_g60[3])&&ast_GmlNodeTools_equals(_g[4],b_i14)&&ast_GmlNodeTools_equals(_g[5],b_i23);
			}else return false;
		case 65:
			var _g61=b;
			if(_g61[1]==65){
				var b_v10=_g61[6];
				var b_i24=_g61[5];
				var b_i15=_g61[4];
				return ast_GmlNodeTools_equals(_g[3],_g61[3])&&ast_GmlNodeTools_equals(_g[4],b_i15)&&ast_GmlNodeTools_equals(_g[5],b_i24)&&ast_GmlNodeTools_equals(_g[6],b_v10);
			}else return false;
		case 66:
			var _g62=b;
			if(_g62[1]==66){
				var b_v11=_g62[7];
				var b_o6=_g62[6];
				var b_i25=_g62[5];
				var b_i16=_g62[4];
				return ast_GmlNodeTools_equals(_g[3],_g62[3])&&ast_GmlNodeTools_equals(_g[4],b_i16)&&ast_GmlNodeTools_equals(_g[5],b_i25)&&_g[6]==b_o6&&ast_GmlNodeTools_equals(_g[7],b_v11);
			}else return false;
		case 48:
			var _g44=b;
			if(_g44[1]==48){
				var b_val10=_g44[6];
				var b_op5=_g44[5];
				var b_k2=_g44[4];
				return _g[3]==_g44[3]&&ast_GmlNodeTools_equals(_g[4],b_k2)&&_g[5]==b_op5&&ast_GmlNodeTools_equals(_g[6],b_val10);
			}else return false;
		case 68:
			var _g64=b;
			if(_g64[1]==68){
				var b_inc9=_g64[6];
				var b_k6=_g64[5];
				var b_i8=_g64[4];
				return ast_GmlNodeTools_equals(_g[3],_g64[3])&&ast_GmlNodeTools_equals(_g[4],b_i8)&&ast_GmlNodeTools_equals(_g[5],b_k6)&&_g[6]==b_inc9;
			}else return false;
		case 69:
			var _g65=b;
			if(_g65[1]==69){
				var b_id22=_g65[4];
				return ast_GmlNodeTools_equals(_g[3],_g65[3])&&ast_GmlNodeTools_equals(_g[4],b_id22);
			}else return false;
		case 70:
			var _g66=b;
			if(_g66[1]==70){
				var b_v12=_g66[5];
				var b_id23=_g66[4];
				return ast_GmlNodeTools_equals(_g[3],_g66[3])&&ast_GmlNodeTools_equals(_g[4],b_id23)&&ast_GmlNodeTools_equals(_g[5],b_v12);
			}else return false;
		case 71:
			var _g67=b;
			if(_g67[1]==71){
				var b_v13=_g67[6];
				var b_o7=_g67[5];
				var b_id24=_g67[4];
				return ast_GmlNodeTools_equals(_g[3],_g67[3])&&ast_GmlNodeTools_equals(_g[4],b_id24)&&_g[5]==b_o7&&ast_GmlNodeTools_equals(_g[6],b_v13);
			}else return false;
		case 72:
			var _g68=b;
			if(_g68[1]==72){
				var b_inc10=_g68[5];
				var b_i9=_g68[4];
				return ast_GmlNodeTools_equals(_g[3],_g68[3])&&ast_GmlNodeTools_equals(_g[4],b_i9)&&_g[5]==b_inc10;
			}else return false;
		case 73:
			var _g69=b;
			if(_g69[1]==73){
				var b_inc11=_g69[5];
				var b_i10=_g69[4];
				return ast_GmlNodeTools_equals(_g[3],_g69[3])&&ast_GmlNodeTools_equals(_g[4],b_i10)&&_g[5]==b_inc11;
			}else return false;
		case 74:
			var _g70=b;
			if(_g70[1]==74){
				var b_id25=_g70[4];
				return ast_GmlNodeTools_equals(_g[3],_g70[3])&&ast_GmlNodeTools_equals(_g[4],b_id25);
			}else return false;
		case 75:
			var _g71=b;
			if(_g71[1]==75){
				var b_v14=_g71[5];
				var b_id26=_g71[4];
				return ast_GmlNodeTools_equals(_g[3],_g71[3])&&ast_GmlNodeTools_equals(_g[4],b_id26)&&ast_GmlNodeTools_equals(_g[5],b_v14);
			}else return false;
		case 47:
			var _g43=b;
			if(_g43[1]==47){
				var b_val9=_g43[5];
				var b_k1=_g43[4];
				return _g[3]==_g43[3]&&ast_GmlNodeTools_equals(_g[4],b_k1)&&ast_GmlNodeTools_equals(_g[5],b_val9);
			}else return false;
		case 46:
			var _g42=b;
			if(_g42[1]==46){
				var b_k=_g42[4];
				return _g[3]==_g42[3]&&ast_GmlNodeTools_equals(_g[4],b_k);
			}else return false;
		case 77:
			var _g73=b;
			if(_g73[1]==77){
				var b_inc12=_g73[5];
				var b_i17=_g73[4];
				return ast_GmlNodeTools_equals(_g[3],_g73[3])&&ast_GmlNodeTools_equals(_g[4],b_i17)&&_g[5]==b_inc12;
			}else return false;
		case 78:
			var _g74=b;
			if(_g74[1]==78){
				var b_inc13=_g74[5];
				var b_i18=_g74[4];
				return ast_GmlNodeTools_equals(_g[3],_g74[3])&&ast_GmlNodeTools_equals(_g[4],b_i18)&&_g[5]==b_inc13;
			}else return false;
		case 79:
			var _g75=b;
			if(_g75[1]==79){
				var b_i26=_g75[5];
				var b_i19=_g75[4];
				return ast_GmlNodeTools_equals(_g[3],_g75[3])&&ast_GmlNodeTools_equals(_g[4],b_i19)&&ast_GmlNodeTools_equals(_g[5],b_i26);
			}else return false;
		case 80:
			var _g76=b;
			if(_g76[1]==80){
				var b_v16=_g76[6];
				var b_i27=_g76[5];
				var b_i110=_g76[4];
				return ast_GmlNodeTools_equals(_g[3],_g76[3])&&ast_GmlNodeTools_equals(_g[4],b_i110)&&ast_GmlNodeTools_equals(_g[5],b_i27)&&ast_GmlNodeTools_equals(_g[6],b_v16);
			}else return false;
		case 81:
			var _g77=b;
			if(_g77[1]==81){
				var b_v17=_g77[7];
				var b_o9=_g77[6];
				var b_i28=_g77[5];
				var b_i111=_g77[4];
				return ast_GmlNodeTools_equals(_g[3],_g77[3])&&ast_GmlNodeTools_equals(_g[4],b_i111)&&ast_GmlNodeTools_equals(_g[5],b_i28)&&_g[6]==b_o9&&ast_GmlNodeTools_equals(_g[7],b_v17);
			}else return false;
		case 82:
			var _g78=b;
			if(_g78[1]==82){
				var b_inc14=_g78[6];
				var b_k7=_g78[5];
				var b_i20=_g78[4];
				return ast_GmlNodeTools_equals(_g[3],_g78[3])&&ast_GmlNodeTools_equals(_g[4],b_i20)&&ast_GmlNodeTools_equals(_g[5],b_k7)&&_g[6]==b_inc14;
			}else return false;
		case 83:
			var _g79=b;
			if(_g79[1]==83){
				var b_inc15=_g79[6];
				var b_k8=_g79[5];
				var b_i29=_g79[4];
				return ast_GmlNodeTools_equals(_g[3],_g79[3])&&ast_GmlNodeTools_equals(_g[4],b_i29)&&ast_GmlNodeTools_equals(_g[5],b_k8)&&_g[6]==b_inc15;
			}else return false;
		case 84:
			var a_value2=_g[4];
			var _g80=b;
			if(_g80[1]==84){
				var b_value2=_g80[4];
				if(_g[3]==_g80[3]){
					if(a_value2!=null){
						return b_value2!=null&&ast_GmlNodeTools_equals(a_value2,b_value2);
					}else return b_value2==null;
				}else return false;
			}else return false;
		case 85:
			var _g81=b;
			if(_g81[1]==85){
				return ast_GmlNodeTools_equalsList(_g[3],_g81[3]);
			}else return false;
		case 86:
			var a_not1=_g[5];
			var _g82=b;
			if(_g82[1]==86){
				var b_not1=_g82[5];
				var b_then=_g82[4];
				if(ast_GmlNodeTools_equals(_g[3],_g82[3])&&ast_GmlNodeTools_equals(_g[4],b_then)){
					if(a_not1!=null){
						return b_not1!=null&&ast_GmlNodeTools_equals(a_not1,b_not1);
					}else return b_not1==null;
				}else return false;
			}else return false;
		case 87:
			var _g83=b;
			if(_g83[1]==87){
				var b_not2=_g83[5];
				var b_then1=_g83[4];
				return ast_GmlNodeTools_equals(_g[3],_g83[3])&&ast_GmlNodeTools_equals(_g[4],b_then1)&&ast_GmlNodeTools_equals(_g[5],b_not2);
			}else return false;
		case 89:
			var _g85=b;
			if(_g85[1]==89){
				return ast_GmlNodeTools_equals(_g[3],_g85[3]);
			}else return false;
		case 45:
			var _g41=b;
			if(_g41[1]==45){
				var b_v3=_g41[6];
				var b_op4=_g41[5];
				var b_fd6=_g41[4];
				return ast_GmlNodeTools_equals(_g[3],_g41[3])&&_g[4]==b_fd6&&_g[5]==b_op4&&ast_GmlNodeTools_equals(_g[6],b_v3);
			}else return false;
		case 91:
			var _g86=b;
			if(_g86[1]==91){
				var b_node=_g86[4];
				return ast_GmlNodeTools_equals(_g[3],_g86[3])&&ast_GmlNodeTools_equals(_g[4],b_node);
			}else return false;
		case 92:
			var _g87=b;
			if(_g87[1]==92){
				var b_cond3=_g87[4];
				return ast_GmlNodeTools_equals(_g[3],_g87[3])&&ast_GmlNodeTools_equals(_g[4],b_cond3);
			}else return false;
		case 93:
			var _g88=b;
			if(_g88[1]==93){
				var b_cond4=_g88[4];
				return ast_GmlNodeTools_equals(_g[3],_g88[3])&&ast_GmlNodeTools_equals(_g[4],b_cond4);
			}else return false;
		case 44:
			var _g40=b;
			if(_g40[1]==44){
				var b_v2=_g40[5];
				var b_fd5=_g40[4];
				return ast_GmlNodeTools_equals(_g[3],_g40[3])&&_g[4]==b_fd5&&ast_GmlNodeTools_equals(_g[5],b_v2);
			}else return false;
		case 95:
			var _g90=b;
			if(_g90[1]==95){
				var b_loop=_g90[6];
				var b_post=_g90[5];
				var b_cond5=_g90[4];
				return ast_GmlNodeTools_equals(_g[3],_g90[3])&&ast_GmlNodeTools_equals(_g[4],b_cond5)&&ast_GmlNodeTools_equals(_g[5],b_post)&&ast_GmlNodeTools_equals(_g[6],b_loop);
			}else return false;
		case 96:
			var _g91=b;
			if(_g91[1]==96){
				var b_node4=_g91[4];
				return ast_GmlNodeTools_equals(_g[3],_g91[3])&&ast_GmlNodeTools_equals(_g[4],b_node4);
			}else return false;
		case 97:
			var _g92=b;
			if(_g92[1]==97){
				return ast_GmlNodeTools_equals(_g[3],_g92[3]);
			}else return false;
		case 98:
			var _g93=b;
			if(_g93[1]==98){
				return ast_GmlNodeTools_equals(_g[3],_g93[3]);
			}else return false;
		case 43:
			var _g39=b;
			if(_g39[1]==43){
				var b_fd4=_g39[4];
				return ast_GmlNodeTools_equals(_g[3],_g39[3])&&_g[4]==b_fd4;
			}else return false;
		case 14:
			var _g11=b;
			if(_g11[1]==14){
				return ast_GmlNodeTools_equals(_g[3],_g11[3]);
			}else return false;
		case 42:
			var _g38=b;
			if(_g38[1]==42){
				var b_val8=_g38[5];
				var b_op3=_g38[4];
				return _g[3]==_g38[3]&&_g[4]==b_op3&&ast_GmlNodeTools_equals(_g[5],b_val8);
			}else return false;
		case 41:
			var _g37=b;
			if(_g37[1]==41){
				var b_val7=_g37[4];
				return _g[3]==_g37[3]&&ast_GmlNodeTools_equals(_g[4],b_val7);
			}else return false;
		case 103:
			var _g94=b;
			if(_g94[1]==103){
				var b_i30=_g94[4];
				return ast_GmlNodeTools_equals(_g[3],_g94[3])&&_g[4]==b_i30;
			}else return false;
		case 104:
			var _g95=b;
			if(_g95[1]==104){
				var b_name2=_g95[4];
				return _g[3]==_g95[3]&&_g[4]==b_name2;
			}else return false;
		case 105:
			var _g96=b;
			if(_g96[1]==105){
				var b_name3=_g96[4];
				return _g[3]==_g96[3]&&_g[4]==b_name3;
			}else return false;
		case 106:
			var _g97=b;
			if(_g97[1]==106){
				return _g[3]==_g97[3];
			}else return false;
		case 107:
			var _g98=b;
			if(_g98[1]==107){
				return _g[3]==_g98[3];
			}else return false;
		case 108:
			var _g99=b;
			if(_g99[1]==108){
				return _g[3]==_g99[3];
			}else return false;
		case 109:
			var _g100=b;
			if(_g100[1]==109){
				var b_x37=_g100[4];
				return _g[3]==_g100[3]&&ast_GmlNodeTools_equals(_g[4],b_x37);
			}else return false;
		case 110:
			var _g101=b;
			if(_g101[1]==110){
				var b_s6=_g101[4];
				return ast_GmlNodeTools_equals(_g[3],_g101[3])&&_g[4]==b_s6;
			}else return false;
		case 111:
			var _g102=b;
			if(_g102[1]==111){
				var b_x39=_g102[4];
				return _g[3]==_g102[3]&&ast_GmlNodeTools_equals(_g[4],b_x39);
			}else return false;
		case 112:
			var _g103=b;
			if(_g103[1]==112){
				return _g[3]==_g103[3];
			}else return false;
		case 113:
			var _g104=b;
			if(_g104[1]==113){
				var b_pl=_g104[5];
				var b_x40=_g104[4];
				return _g[3]==_g104[3]&&ast_GmlNodeTools_equals(_g[4],b_x40)&&_g[5]==b_pl;
			}else return false;
		case 114:
			var _g105=b;
			if(_g105[1]==114){
				var b_pl1=_g105[5];
				var b_s10=_g105[4];
				return ast_GmlNodeTools_equals(_g[3],_g105[3])&&_g[4]==b_s10&&_g[5]==b_pl1;
			}else return false;
		case 40:
			var _g36=b;
			if(_g36[1]==40){
				return _g[3]==_g36[3];
			}else return false;
		case 13:
			var _g10=b;
			if(_g10[1]==13){
				return _g[3]==_g10[3];
			}else return false;
		case 4:
			var _g4=b;
			if(_g4[1]==4){
				return ast_GmlNodeTools_equalsList(_g[3],_g4[3]);
			}else return false;
		case 5:
			var m1=_g[4];
			var _g5=b;
			if(_g5[1]==5){
				var m2=_g5[4];
				var k2=_g5[3];
				n=m1.length;
				if(m2.length==n){
					i=0;
					while(i<n){
						if(_g[3][i]==k2[i]&&ast_GmlNodeTools_equals(m1[i],m2[i])){
							++i;
						}else break;
					}
					return i>=n;
				}else return false;
			}else return false;
		case 88:
			var o1=_g[5];
			var m11=_g[4];
			var _g84=b;
			if(_g84[1]==88){
				var o2=_g84[5];
				var m21=_g84[4];
				if(ast_GmlNodeTools_equals(_g[3],_g84[3])&&(o1!=null&&o2!=null&&ast_GmlNodeTools_equals(o1,o2)||o1==null&&o2==null)){
					n=m11.length;
					if(m21.length!=n)return false;
					i=0;
					while(i<n){
						if(ast_GmlNodeTools_equals(m11[i].expr,m21[i].expr)&&ast_GmlNodeTools_equalsList(m11[i].values,m21[i].values)){
							++i;
						}else break;
					}
					return i>=n;
				}else return false;
			}else return false;
	}
}
function ast_GmlNodeTools_cloneOpt(q){
	if(q!=null){
		return ast_GmlNodeTools_clone(q);
	}else return null;
}
function ast_GmlNodeTools_clone(q){
	var xw, i, n, fi;
	var d=q[2];
	var _g=q;
	switch(_g[1]){
		case 0:return ast_GmlNodeDef_Undefined(d);
		case 3:return ast_GmlNodeDef_EnumCtr(d,_g[3],_g[4]);
		case 5:
			xw=_g[4].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_ObjectDecl(d,_g[3].slice(0),xw);
		case 6:return ast_GmlNodeDef_EnsureArray(d,ast_GmlNodeTools_clone(_g[3]));
		case 7:return ast_GmlNodeDef_Ident(d,_g[3]);
		case 8:return ast_GmlNodeDef_Self(d);
		case 2:return ast_GmlNodeDef_CString(d,_g[3]);
		case 10:return ast_GmlNodeDef_GlobalRef(d);
		case 11:return ast_GmlNodeDef_Script(d,_g[3]);
		case 12:return ast_GmlNodeDef_Const(d,_g[3]);
		case 14:return ast_GmlNodeDef_ArgIndex(d,ast_GmlNodeTools_clone(_g[3]));
		case 15:return ast_GmlNodeDef_ArgCount(d);
		case 16:
			xw=_g[4].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_Call(d,ast_GmlNodeTools_clone(_g[3]),xw);
		case 17:
			xw=_g[4].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallScript(d,_g[3],xw);
		case 18:
			xw=_g[5].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallScriptAt(d,ast_GmlNodeTools_clone(_g[3]),_g[4],xw);
		case 19:
			xw=_g[4].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallScriptId(d,ast_GmlNodeTools_clone(_g[3]),xw);
		case 20:
			xw=_g[5].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallField(d,ast_GmlNodeTools_clone(_g[3]),_g[4],xw);
		case 21:
			xw=_g[4].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallFunc(d,_g[3],xw);
		case 22:
			xw=_g[5].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_CallFuncAt(d,ast_GmlNodeTools_clone(_g[3]),_g[4],xw);
		case 23:return ast_GmlNodeDef_Prefix(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 24:return ast_GmlNodeDef_Postfix(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 25:return ast_GmlNodeDef_UnOp(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 26:return ast_GmlNodeDef_BinOp(d,_g[3],ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 27:return ast_GmlNodeDef_SetOp(d,_g[3],ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 28:return ast_GmlNodeDef_ToBool(d,ast_GmlNodeTools_clone(_g[3]));
		case 9:return ast_GmlNodeDef_Other(d);
		case 30:return ast_GmlNodeDef_In(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 31:return ast_GmlNodeDef_Local(d,_g[3]);
		case 32:return ast_GmlNodeDef_LocalSet(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 33:return ast_GmlNodeDef_LocalAop(d,_g[3],_g[4],ast_GmlNodeTools_clone(_g[5]));
		case 34:return ast_GmlNodeDef_Global(d,_g[3]);
		case 35:return ast_GmlNodeDef_GlobalSet(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 36:return ast_GmlNodeDef_GlobalAop(d,_g[3],_g[4],ast_GmlNodeTools_clone(_g[5]));
		case 37:return ast_GmlNodeDef_Field(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 38:return ast_GmlNodeDef_FieldSet(d,ast_GmlNodeTools_clone(_g[3]),_g[4],ast_GmlNodeTools_clone(_g[5]));
		case 39:return ast_GmlNodeDef_FieldAop(d,ast_GmlNodeTools_clone(_g[3]),_g[4],_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 41:return ast_GmlNodeDef_EnvSet(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 42:return ast_GmlNodeDef_EnvAop(d,_g[3],_g[4],ast_GmlNodeTools_clone(_g[5]));
		case 43:return ast_GmlNodeDef_EnvFd(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 44:return ast_GmlNodeDef_EnvFdSet(d,ast_GmlNodeTools_clone(_g[3]),_g[4],ast_GmlNodeTools_clone(_g[5]));
		case 45:return ast_GmlNodeDef_EnvFdAop(d,ast_GmlNodeTools_clone(_g[3]),_g[4],_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 46:return ast_GmlNodeDef_Env1d(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 47:return ast_GmlNodeDef_Env1dSet(d,_g[3],ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 48:return ast_GmlNodeDef_Env1dAop(d,_g[3],ast_GmlNodeTools_clone(_g[4]),_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 49:return ast_GmlNodeDef_Index(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 50:return ast_GmlNodeDef_IndexSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 51:return ast_GmlNodeDef_IndexAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 52:return ast_GmlNodeDef_IndexPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 53:return ast_GmlNodeDef_IndexPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 54:return ast_GmlNodeDef_Index2d(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 55:return ast_GmlNodeDef_Index2dSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),ast_GmlNodeTools_clone(_g[6]));
		case 56:return ast_GmlNodeDef_Index2dAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6],ast_GmlNodeTools_clone(_g[7]));
		case 57:return ast_GmlNodeDef_Index2dPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 58:return ast_GmlNodeDef_Index2dPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 59:return ast_GmlNodeDef_RawId(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 60:return ast_GmlNodeDef_RawIdSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 61:return ast_GmlNodeDef_RawIdAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 62:return ast_GmlNodeDef_RawIdPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 63:return ast_GmlNodeDef_RawIdPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 64:return ast_GmlNodeDef_RawId2d(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 65:return ast_GmlNodeDef_RawId2dSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),ast_GmlNodeTools_clone(_g[6]));
		case 66:return ast_GmlNodeDef_RawId2dAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6],ast_GmlNodeTools_clone(_g[7]));
		case 67:return ast_GmlNodeDef_RawId2dPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 68:return ast_GmlNodeDef_RawId2dPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 69:return ast_GmlNodeDef_DsList(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 70:return ast_GmlNodeDef_DsListSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 71:return ast_GmlNodeDef_DsListAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 72:return ast_GmlNodeDef_DsListPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 73:return ast_GmlNodeDef_DsListPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 74:return ast_GmlNodeDef_DsMap(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 75:return ast_GmlNodeDef_DsMapSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 76:return ast_GmlNodeDef_DsMapAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5],ast_GmlNodeTools_clone(_g[6]));
		case 77:return ast_GmlNodeDef_DsMapPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 78:return ast_GmlNodeDef_DsMapPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 79:return ast_GmlNodeDef_DsGrid(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 80:return ast_GmlNodeDef_DsGridSet(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),ast_GmlNodeTools_clone(_g[6]));
		case 81:return ast_GmlNodeDef_DsGridAop(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6],ast_GmlNodeTools_clone(_g[7]));
		case 82:return ast_GmlNodeDef_DsGridPrefix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 83:return ast_GmlNodeDef_DsGridPostfix(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),_g[6]);
		case 84:return ast_GmlNodeDef_VarDecl(d,_g[3],ast_GmlNodeTools_cloneOpt(_g[4]));
		case 85:
			xw=_g[3].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_Block(d,xw);
		case 86:return ast_GmlNodeDef_IfThen(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_cloneOpt(_g[5]));
		case 87:return ast_GmlNodeDef_Ternary(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]));
		case 29:return ast_GmlNodeDef_FromBool(d,ast_GmlNodeTools_clone(_g[3]));
		case 89:return ast_GmlNodeDef_Wait(d,ast_GmlNodeTools_clone(_g[3]));
		case 90:return ast_GmlNodeDef_Fork(d);
		case 91:return ast_GmlNodeDef_While(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 92:return ast_GmlNodeDef_DoUntil(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 93:return ast_GmlNodeDef_DoWhile(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 94:return ast_GmlNodeDef_Repeat(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 95:return ast_GmlNodeDef_For(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]),ast_GmlNodeTools_clone(_g[5]),ast_GmlNodeTools_clone(_g[6]));
		case 96:return ast_GmlNodeDef_With(d,ast_GmlNodeTools_clone(_g[3]),ast_GmlNodeTools_clone(_g[4]));
		case 97:return ast_GmlNodeDef_Once(d,ast_GmlNodeTools_clone(_g[3]));
		case 98:return ast_GmlNodeDef_Return(d,ast_GmlNodeTools_clone(_g[3]));
		case 99:return ast_GmlNodeDef_Exit(d);
		case 100:return ast_GmlNodeDef_Break(d);
		case 101:return ast_GmlNodeDef_Continue(d);
		case 102:return ast_GmlNodeDef_Debugger(d);
		case 103:return ast_GmlNodeDef_Yield(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 104:return ast_GmlNodeDef_Label(d,_g[3],_g[4]);
		case 105:return ast_GmlNodeDef_Jump(d,_g[3],_g[4]);
		case 106:return ast_GmlNodeDef_UserLabel(d,_g[3]);
		case 107:return ast_GmlNodeDef_UserJump(d,_g[3]);
		case 108:return ast_GmlNodeDef_CommentLine(d,_g[3]);
		case 109:return ast_GmlNodeDef_CommentLinePre(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 110:return ast_GmlNodeDef_CommentLinePost(d,ast_GmlNodeTools_clone(_g[3]),_g[4]);
		case 111:return ast_GmlNodeDef_CommentLineSep(d,_g[3],ast_GmlNodeTools_clone(_g[4]));
		case 112:return ast_GmlNodeDef_CommentBlock(d,_g[3]);
		case 113:return ast_GmlNodeDef_CommentBlockPre(d,_g[3],ast_GmlNodeTools_clone(_g[4]),_g[5]);
		case 114:return ast_GmlNodeDef_CommentBlockPost(d,ast_GmlNodeTools_clone(_g[3]),_g[4],_g[5]);
		case 40:return ast_GmlNodeDef_Env(d,_g[3]);
		case 13:return ast_GmlNodeDef_ArgConst(d,_g[3]);
		case 4:
			xw=_g[3].slice();
			fi=xw.length;
			while(--fi>=0){
				xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
			}
			return ast_GmlNodeDef_ArrayDecl(d,xw);
		case 1:return ast_GmlNodeDef_Number(d,_g[3],_g[4]);
		case 88:
			var m=_g[4];
			m=m.slice();
			n=m.length;
			for(i=0;i<n;++i){
				var cc=m[i];
				xw=cc.values.slice();
				fi=xw.length;
				while(--fi>=0){
					xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
				}
				cc={
					values:xw,
					expr:ast_GmlNodeTools_clone(cc.expr),
					pre:cc.pre
				};
				m[i]=cc;
				xw=cc.pre.slice();
				fi=xw.length;
				while(--fi>=0){
					xw[fi]=ast_GmlNodeTools_clone(xw[fi]);
				}
				cc.pre=xw;
			}
			return ast_GmlNodeDef_Switch(_g[2],ast_GmlNodeTools_clone(_g[3]),m,ast_GmlNodeTools_cloneOpt(_g[5]));
	}
}
function ast_GmlNodeTools_seekAllOut(q,st,c,si){
	var x, w, i, n;
	var par=st[si];
	if(par==null)return false;
	var _g=par;
	switch(_g[1]){
		case 85:
			w=_g[3];
			i=w.length;
			while(--i>=0){
				if(w[i]==q)break;
			}
			while(--i>=0){
				if(c(w[i],null))return true;
			}
			break;
		case 86:
			var c1=_g[3];
			if(c1!=q&&c(c1,null))return true;
			break;
		case 91:
			var c3=_g[3];
			if(c3!=q&&c(c3,null))return true;
			break;
		case 93:
			var c5=_g[3];
			if(c5!=q&&c(c5,null))return true;
			break;
		case 92:
			var c4=_g[3];
			if(c4!=q&&c(c4,null))return true;
			break;
		case 94:
			var c6=_g[3];
			if(c6!=q&&c(c6,null))return true;
			break;
		case 95:
			var c7=_g[3];
			if(c7!=q&&c(c7,null))return true;
			break;
		case 88:
			var c2=_g[3];
			if(c2!=q&&c(c2,null))return true;
			break;
		case 96:
			var c8=_g[3];
			if(c8!=q&&c(c8,null))return true;
			break;
		case 110:break;
		case 109:break;
		case 111:break;
		case 113:break;
		case 114:break;
		default:throw new js__Boot_HaxeError("Can't seekAllOut over "+par[2].toString()+" "+par[0]);
	}
	return ast_GmlNodeTools_seekAllOut(par,st,c,si+1);
}
function ast_GmlNodeTools_seekAll(q,st,c){
	if(st!=null)st.unshift(q);
	var r, x, w, i, n;
	var _g=q;
	switch(_g[1]){
		case 89:r=c(_g[3],null);break;
		case 29:r=c(_g[3],null);break;
		case 110:r=c(_g[3],null);break;
		case 109:r=c(_g[4],null);break;
		case 103:r=c(_g[3],null);break;
		case 35:r=c(_g[4],null);break;
		case 28:r=c(_g[3],null);break;
		case 113:r=c(_g[4],null);break;
		case 6:r=c(_g[3],null);break;
		case 111:r=c(_g[4],null);break;
		case 24:r=c(_g[3],null);break;
		case 33:r=c(_g[5],null);break;
		case 14:r=c(_g[3],null);break;
		case 42:r=c(_g[5],null);break;
		case 41:r=c(_g[4],null);break;
		case 97:r=c(_g[3],null);break;
		case 23:r=c(_g[3],null);break;
		case 98:r=c(_g[3],null);break;
		case 36:r=c(_g[5],null);break;
		case 32:r=c(_g[4],null);break;
		case 114:r=c(_g[3],null);break;
		case 3:r=false;break;
		case 11:r=false;break;
		case 100:r=false;break;
		case 99:r=false;break;
		case 101:r=false;break;
		case 104:r=false;break;
		case 9:r=false;break;
		case 31:r=false;break;
		case 108:r=false;break;
		case 34:r=false;break;
		case 106:r=false;break;
		case 7:r=false;break;
		case 105:r=false;break;
		case 102:r=false;break;
		case 10:r=false;break;
		case 12:r=false;break;
		case 2:r=false;break;
		case 90:r=false;break;
		case 8:r=false;break;
		case 112:r=false;break;
		case 15:r=false;break;
		case 107:r=false;break;
		case 1:r=false;break;
		case 0:r=false;break;
		case 40:r=false;break;
		case 13:r=false;break;
		case 26:
			switch(_g[3]){
				case 80:
					var b=_g[5];
					r=c(_g[4],null)&&c(b,null);
					break;
				case 96:
					var b1=_g[5];
					r=c(_g[4],null);
					break;
				default:
					var l_b=_g[5];
					var l_a=_g[4];
					var l_o=_g[3];
					r=c(l_a,null)||c(l_b,null);
			}
			break;
		case 5:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],null))break;
			r=i<n;
			break;
		case 4:
			w=_g[3];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],null))break;
			r=i<n;
			break;
		case 84:
			var v=_g[4];
			r=v!=null&&c(v,null);
			break;
		case 25:r=c(_g[3],null);break;
		case 85:
			w=_g[3];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],null))break;
			r=i<n;
			break;
		case 19:
			if(c(_g[3],null)){
				r=true;
			}else {
				w=_g[4];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],null))break;
				r=i<n;
			}
			break;
		case 16:
			if(c(_g[3],null)){
				r=true;
			}else {
				w=_g[4];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],null))break;
				r=i<n;
			}
			break;
		case 20:
			if(c(_g[3],null)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],null))break;
				r=i<n;
			}
			break;
		case 18:
			if(c(_g[3],null)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],null))break;
				r=i<n;
			}
			break;
		case 22:
			if(c(_g[3],null)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],null))break;
				r=i<n;
			}
			break;
		case 21:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],null))break;
			r=i<n;
			break;
		case 17:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],null))break;
			r=i<n;
			break;
		case 86:
			var b2=_g[5];
			r=c(_g[3],null)||b2!=null&&c(_g[4],null)&&c(b2,null);
			break;
		case 87:r=c(_g[3],null)||c(_g[4],null)&&c(_g[5],null);break;
		case 95:r=c(_g[3],null)||c(_g[4],null);break;
		case 91:r=c(_g[3],null);break;
		case 96:r=c(_g[3],null);break;
		case 93:r=c(_g[3],null);break;
		case 92:r=c(_g[3],null);break;
		case 94:r=c(_g[3],null);break;
		case 88:
			if(c(_g[3],null)){
				r=true;
			}else {
				x=_g[5];
				if(x!=null&&c(x,null)){
					n=_g[4].length;
					i=0;
					while(i<n){
						if(c(x,null)){
							++i;
						}else break;
					}
					r=i>=n;
				}else r=false;
			}
			break;
		case 27:r=c(_g[4],null)||c(_g[5],null);break;
		case 30:r=c(_g[3],null)||c(_g[4],null);break;
		case 46:r=c(_g[4],null);break;
		case 47:r=c(_g[4],null)||c(_g[5],null);break;
		case 48:r=c(_g[4],null)||c(_g[6],null);break;
		case 49:r=c(_g[3],null)||c(_g[4],null);break;
		case 50:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 51:r=c(_g[3],null)||c(_g[4],null)||c(_g[6],null);break;
		case 52:r=c(_g[3],null)||c(_g[4],null);break;
		case 53:r=c(_g[3],null)||c(_g[4],null);break;
		case 54:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 55:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[6],null);break;
		case 56:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[7],null);break;
		case 57:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 58:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 59:r=c(_g[3],null)||c(_g[4],null);break;
		case 60:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 61:r=c(_g[3],null)||c(_g[4],null)||c(_g[6],null);break;
		case 62:r=c(_g[3],null)||c(_g[4],null);break;
		case 63:r=c(_g[3],null)||c(_g[4],null);break;
		case 64:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 65:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[6],null);break;
		case 66:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[7],null);break;
		case 67:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 68:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 37:r=c(_g[3],null);break;
		case 38:r=c(_g[3],null)||c(_g[5],null);break;
		case 39:r=c(_g[3],null)||c(_g[6],null);break;
		case 43:r=c(_g[3],null);break;
		case 44:r=c(_g[3],null)||c(_g[5],null);break;
		case 45:r=c(_g[3],null)||c(_g[6],null);break;
		case 69:r=c(_g[3],null)||c(_g[4],null);break;
		case 70:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 71:r=c(_g[3],null)||c(_g[4],null)||c(_g[6],null);break;
		case 72:r=c(_g[3],null)||c(_g[4],null);break;
		case 73:r=c(_g[3],null)||c(_g[4],null);break;
		case 74:r=c(_g[3],null)||c(_g[4],null);break;
		case 75:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 76:r=c(_g[3],null)||c(_g[4],null)||c(_g[6],null);break;
		case 77:r=c(_g[3],null)||c(_g[4],null);break;
		case 78:r=c(_g[3],null)||c(_g[4],null);break;
		case 79:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 80:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[6],null);break;
		case 81:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null)||c(_g[7],null);break;
		case 82:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
		case 83:r=c(_g[3],null)||c(_g[4],null)||c(_g[5],null);break;
	}
	if(st!=null)st.shift();
	return false;
}
function ast_GmlNodeTools_seek(q,st,c){
	if(st!=null)st.unshift(q);
	var r, x, w, i, n, k, l;
	var _g=q;
	switch(_g[1]){
		case 0:r=false;break;
		case 3:r=false;break;
		case 5:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],st))break;
			r=i<n;
			break;
		case 6:r=c(_g[3],st);break;
		case 7:r=false;break;
		case 8:r=false;break;
		case 2:r=false;break;
		case 10:r=false;break;
		case 11:r=false;break;
		case 12:r=false;break;
		case 14:r=c(_g[3],st);break;
		case 15:r=false;break;
		case 16:
			if(c(_g[3],st)){
				r=true;
			}else {
				w=_g[4];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],st))break;
				r=i<n;
			}
			break;
		case 17:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],st))break;
			r=i<n;
			break;
		case 18:
			if(c(_g[3],st)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],st))break;
				r=i<n;
			}
			break;
		case 19:
			if(c(_g[3],st)){
				r=true;
			}else {
				w=_g[4];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],st))break;
				r=i<n;
			}
			break;
		case 20:
			if(c(_g[3],st)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],st))break;
				r=i<n;
			}
			break;
		case 21:
			w=_g[4];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],st))break;
			r=i<n;
			break;
		case 22:
			if(c(_g[3],st)){
				r=true;
			}else {
				w=_g[5];
				n=w.length;
				for(i=0;i<n;++i)if(c(w[i],st))break;
				r=i<n;
			}
			break;
		case 23:r=c(_g[3],st);break;
		case 24:r=c(_g[3],st);break;
		case 25:r=c(_g[3],st);break;
		case 26:r=c(_g[4],st)||c(_g[5],st);break;
		case 27:r=c(_g[4],st)||c(_g[5],st);break;
		case 28:r=c(_g[3],st);break;
		case 9:r=false;break;
		case 30:r=c(_g[3],st)||c(_g[4],st);break;
		case 31:r=false;break;
		case 32:r=c(_g[4],st);break;
		case 33:r=c(_g[5],st);break;
		case 34:r=false;break;
		case 35:r=c(_g[4],st);break;
		case 36:r=c(_g[5],st);break;
		case 37:r=c(_g[3],st);break;
		case 38:r=c(_g[3],st)||c(_g[5],st);break;
		case 39:r=c(_g[3],st)||c(_g[6],st);break;
		case 41:r=c(_g[4],st);break;
		case 42:r=c(_g[5],st);break;
		case 43:r=c(_g[3],st);break;
		case 44:r=c(_g[3],st)||c(_g[5],st);break;
		case 45:r=c(_g[3],st)||c(_g[6],st);break;
		case 46:r=c(_g[4],st);break;
		case 47:r=c(_g[4],st)||c(_g[5],st);break;
		case 48:r=c(_g[4],st)||c(_g[6],st);break;
		case 49:r=c(_g[3],st)||c(_g[4],st);break;
		case 50:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 51:r=c(_g[3],st)||c(_g[4],st)||c(_g[6],st);break;
		case 52:r=c(_g[3],st)||c(_g[4],st);break;
		case 53:r=c(_g[3],st)||c(_g[4],st);break;
		case 54:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 55:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[6],st);break;
		case 56:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[7],st);break;
		case 57:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 58:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 59:r=c(_g[3],st)||c(_g[4],st);break;
		case 60:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 61:r=c(_g[3],st)||c(_g[4],st)||c(_g[6],st);break;
		case 62:r=c(_g[3],st)||c(_g[4],st);break;
		case 63:r=c(_g[3],st)||c(_g[4],st);break;
		case 64:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 65:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[6],st);break;
		case 66:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[7],st);break;
		case 67:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 68:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 69:r=c(_g[3],st)||c(_g[4],st);break;
		case 70:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 71:r=c(_g[3],st)||c(_g[4],st)||c(_g[6],st);break;
		case 72:r=c(_g[3],st)||c(_g[4],st);break;
		case 73:r=c(_g[3],st)||c(_g[4],st);break;
		case 74:r=c(_g[3],st)||c(_g[4],st);break;
		case 75:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 76:r=c(_g[3],st)||c(_g[4],st)||c(_g[6],st);break;
		case 77:r=c(_g[3],st)||c(_g[4],st);break;
		case 78:r=c(_g[3],st)||c(_g[4],st);break;
		case 79:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 80:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[6],st);break;
		case 81:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[7],st);break;
		case 82:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 83:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 84:
			var l_value2=_g[4];
			r=l_value2!=null&&c(l_value2,st);
			break;
		case 85:
			w=_g[3];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],st))break;
			r=i<n;
			break;
		case 86:
			var l_not1=_g[5];
			r=c(_g[3],st)||c(_g[4],st)||l_not1!=null&&c(l_not1,st);
			break;
		case 87:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st);break;
		case 29:r=c(_g[3],st);break;
		case 89:r=c(_g[3],st);break;
		case 90:r=false;break;
		case 91:r=c(_g[3],st)||c(_g[4],st);break;
		case 92:r=c(_g[3],st)||c(_g[4],st);break;
		case 93:r=c(_g[3],st)||c(_g[4],st);break;
		case 94:r=c(_g[3],st)||c(_g[4],st);break;
		case 95:r=c(_g[3],st)||c(_g[4],st)||c(_g[5],st)||c(_g[6],st);break;
		case 96:r=c(_g[3],st)||c(_g[4],st);break;
		case 97:r=c(_g[3],st);break;
		case 98:r=c(_g[3],st);break;
		case 99:r=false;break;
		case 100:r=false;break;
		case 101:r=false;break;
		case 102:r=false;break;
		case 103:r=c(_g[3],st);break;
		case 104:r=false;break;
		case 105:r=false;break;
		case 106:r=false;break;
		case 107:r=false;break;
		case 108:r=false;break;
		case 109:r=c(_g[4],st);break;
		case 110:r=c(_g[3],st);break;
		case 111:r=c(_g[4],st);break;
		case 112:r=false;break;
		case 113:r=c(_g[4],st);break;
		case 114:r=c(_g[3],st);break;
		case 40:r=false;break;
		case 13:r=false;break;
		case 4:
			w=_g[3];
			n=w.length;
			for(i=0;i<n;++i)if(c(w[i],st))break;
			r=i<n;
			break;
		case 1:r=false;break;
		case 88:
			var o=_g[5];
			var m=_g[4];
			if(c(_g[3],st)){
				r=true;
			}else {
				n=m.length;
				for(i=0;i<n;++i){
					w=m[i].values;
					l=w.length;
					for(k=0;k<l;++k)if(c(w[k],st))break;
					if(k<l||c(m[i].expr,st))break;
				}
				if(i<n){
					r=true;
				}else r=o!=null&&c(o,st);
			}
			break;
	}
	if(st!=null)st.shift();
	return r;
}
function ast__GmlOp_GmlOp_Impl__getPriority(op){
	return op>>4;
}
function ast__GmlOp_GmlOp_Impl__toJS(this1){
	var o=this1;
	return "$"+"0123456789ABCDEF".charAt(o>>4)+"0123456789ABCDEF".charAt(o&15)+"/* "+ast__GmlOp_GmlOp_Impl__toString(this1)+" */";
}
function ast__GmlOp_GmlOp_Impl__toString(this1){
	switch(this1){
		case -1:return "";
		case 0:return "*";
		case 1:return "/";
		case 3:return "div";
		case 2:return "%";
		case 16:return "+";
		case 17:return "-";
		case 18:return "+";
		case 32:return "<<";
		case 33:return ">>";
		case 48:return "|";
		case 49:return "&";
		case 50:return "^";
		case 64:return "==";
		case 65:return "!=";
		case 68:return ">";
		case 66:return "<";
		case 69:return ">=";
		case 67:return "<=";
		case 80:return "&&";
		case 96:return "||";
		default:return ast__GmlOp_GmlOp_Impl__getName(this1);
	}
}
function ast__GmlOp_GmlOp_Impl__getName(this1){
	switch(this1){
		case 1:return "Div";
		case 2:return "Mod";
		case 7:return "priorities";
		case 16:return "Add";
		case 17:return "Sub";
		case 18:return "Cct";
		case 32:return "Shl";
		case 33:return "Shr";
		case 48:return "Or";
		case 49:return "And";
		case 64:return "EQ";
		case 65:return "NE";
		case 66:return "LT";
		case 67:return "LE";
		case 68:return "GT";
		case 69:return "GE";
		case 80:return "BAnd";
		case 96:return "BOr";
		case 50:return "Xor";
		case 3:return "IDiv";
		case 0:return "Mul";
		case -1:return "Set";
		default:return null;
	}
}
function ast_GmlPos(src,row,col){
	this.src=src;
	this.row=row;
	this.col=col;
}
ast_GmlPos.prototype={
	toString:function(){
		return this.src.name+("[L"+this.row+",c"+this.col+"]");
	}
}
function ast_GmlScript(src,name,pos){
	this.hasYield=false;
	this.labelMap=Object.create(null);
	this.labels=1;
	this.namedArgs=null;
	this.arguments=0;
	this.locals=0;
	this.localMap=Object.create(null);
	this.source=src;
	this.name=name;
	this.pos=pos;
}
function ast_GmlSource(name,code,main){
	this.name=name;
	this.code=code;
	if(main==null){
		main=name;
		var i;
		while(true){
			i=main.indexOf("/");
			if(i<0)i=main.indexOf("\\");
			if(i>=0)main=main.substring(i+1);
			if(!(i>=0))break;
		}
		i=main.indexOf(".");
		if(i>=0)main=main.substring(0,i);
	}
	this.main=main;
	this.length=code.length;
	var start=-1;
	var row=1;
	while(true){
		var next=code.indexOf("\n",start+1);
		if(next>=0){
			++row;
			start=next;
		}else break;
	}
	this.eof=new ast_GmlPos(this,row,this.length-start);
}
var ast_GmlToken={__ename__:true}
function ast_GmlToken_Header(d,name,lb){
	var r=["Header",0,d,name,lb];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Macro(d){
	var r=["Macro",1,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Hash(d){
	var r=["Hash",2,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Semico(d){
	var r=["Semico",3,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Comma(d){
	var r=["Comma",4,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Period(d){
	var r=["Period",5,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Colon(d){
	var r=["Colon",6,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_QMark(d){
	var r=["QMark",7,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_AtSign(d){
	var r=["AtSign",8,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Keyword(d,kw){
	var r=["Keyword",9,d,kw];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Ident(d,id){
	var r=["Ident",10,d,id];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Env(d,id){
	var r=["Env",11,d,id];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Undefined(d){
	var r=["Undefined",12,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Number(d,nu,src){
	var r=["Number",13,d,nu,src];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CString(d,st){
	var r=["CString",14,d,st];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_UnOp(d,op){
	var r=["UnOp",15,d,op];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_In(d){
	var r=["In",16,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_Adjfix(d,inc){
	var r=["Adjfix",17,d,inc];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_BinOp(d,op){
	var r=["BinOp",18,d,op];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_SetOp(d,op){
	var r=["SetOp",19,d,op];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_ParOpen(d){
	var r=["ParOpen",20,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_ParClose(d){
	var r=["ParClose",21,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_SqbOpen(d){
	var r=["SqbOpen",22,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_SqbClose(d){
	var r=["SqbClose",23,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CubOpen(d){
	var r=["CubOpen",24,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CubClose(d){
	var r=["CubClose",25,d];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_ArgConst(d,i){
	var r=["ArgConst",26,d,i];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CommentPost(d,s){
	var r=["CommentPost",27,d,s];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CommentLine(d,s){
	var r=["CommentLine",28,d,s];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function ast_GmlToken_CommentBlock(d,s,pl){
	var r=["CommentBlock",29,d,s,pl];
	r.__enum__=ast_GmlToken;
	r.toString=sfjs_toString;
	return r;
}
function gmcr_CrCore_hasArgs(x,w){
	switch(x[1]){
		case 13:return true;
		case 14:return true;
		default:return ast_GmlNodeTools_seek(x,w,gmcr_CrCore_hasArgs);
	}
}
function gmcr_CrCore_hasYield(x,w){
	if(x[1]==103){
		return true;
	}else return ast_GmlNodeTools_seek(x,w,gmcr_CrCore_hasYield);
}
function gmcr_CrCore_hasLabel(x,w){
	if(x[1]==104){
		return true;
	}else return ast_GmlNodeTools_seek(x,w,gmcr_CrCore_hasLabel);
}
function gmcr_CrCore_needsSplit(x,w){
	switch(x[1]){
		case 103:return true;
		case 106:return true;
		case 107:return true;
		default:return ast_GmlNodeTools_seek(x,w,gmcr_CrCore_needsSplit);
	}
}
function gmcr_CrCore_replaceLocal(x,w){
	function id(d,s,z){
		var w1=ast_GmlNodeDef_Ident(d,"l_ctx");
		var k=ast_GmlNodeDef_Number(d,GmlProgram_seekScript.localMap[s]+3,null);
		k=ast_GmlNodeDef_CommentBlockPost(d,k,s,false);
		if(z){
			return ast_GmlNodeDef_RawId(d,w1,k);
		}else return ast_GmlNodeDef_Index(d,w1,k);
	}
	var _g=x;
	switch(_g[1]){
		case 27:
			var _hx_tmp2=_g[4];
			if(_hx_tmp2[1]==31){
				var s3=_hx_tmp2[3];
				var d3=_hx_tmp2[2];
				SfEnumTools_setTo(_g[4],ast_GmlNodeDef_RawId(d3,ast_GmlNodeDef_Ident(d3,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d3,ast_GmlNodeDef_Number(d3,GmlProgram_seekScript.localMap[s3]+3,null),s3,false)));
			}
			break;
		case 32:
			var s5=_g[3];
			var d5=_g[2];
			SfEnumTools_setTo(x,ast_GmlNodeDef_RawIdSet(d5,ast_GmlNodeDef_Ident(d5,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d5,ast_GmlNodeDef_Number(d5,GmlProgram_seekScript.localMap[s5]+3,null),s5,false),_g[4]));
			break;
		case 33:
			var s6=_g[3];
			var d6=_g[2];
			SfEnumTools_setTo(x,ast_GmlNodeDef_RawIdAop(d6,ast_GmlNodeDef_Ident(d6,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d6,ast_GmlNodeDef_Number(d6,GmlProgram_seekScript.localMap[s6]+3,null),s6,false),_g[4],_g[5]));
			break;
		case 23:
			var _hx_tmp=_g[3];
			if(_hx_tmp[1]==31){
				var s1=_hx_tmp[3];
				var d1=_hx_tmp[2];
				SfEnumTools_setTo(_g[3],ast_GmlNodeDef_RawId(d1,ast_GmlNodeDef_Ident(d1,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d1,ast_GmlNodeDef_Number(d1,GmlProgram_seekScript.localMap[s1]+3,null),s1,false)));
			}
			break;
		case 24:
			var _hx_tmp1=_g[3];
			if(_hx_tmp1[1]==31){
				var s2=_hx_tmp1[3];
				var d2=_hx_tmp1[2];
				SfEnumTools_setTo(_g[3],ast_GmlNodeDef_RawId(d2,ast_GmlNodeDef_Ident(d2,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d2,ast_GmlNodeDef_Number(d2,GmlProgram_seekScript.localMap[s2]+3,null),s2,false)));
			}
			break;
		case 31:
			var s4=_g[3];
			var d4=_g[2];
			SfEnumTools_setTo(x,ast_GmlNodeDef_Index(d4,ast_GmlNodeDef_Ident(d4,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d4,ast_GmlNodeDef_Number(d4,GmlProgram_seekScript.localMap[s4]+3,null),s4,false)));
			break;
		case 84:
			var v2=_g[4];
			var s7=_g[3];
			var d7=_g[2];
			if(v2!=null){
				SfEnumTools_setTo(x,ast_GmlNodeDef_RawIdSet(d7,ast_GmlNodeDef_Ident(d7,"l_ctx"),ast_GmlNodeDef_CommentBlockPost(d7,ast_GmlNodeDef_Number(d7,GmlProgram_seekScript.localMap[s7]+3,null),s7,false),v2));
			}else SfEnumTools_setTo(x,ast_GmlNodeDef_Block(d7,[]));
			break;
	}
	return ast_GmlNodeTools_seek(x,w,gmcr_CrCore_replaceLocal);
}
function gmcr_CrCore_unroll(r,st){
	var w, h, d, i, s;
	function procLoop(q,jc,jb){
		var fn=null;
		fn=function(q1,st1){
			var _g=q1;
			switch(_g[1]){
				case 101:if(jc>=0)SfEnumTools_setTo(q1,ast_GmlNodeDef_Jump(_g[2],jc,"continue"));break;
				case 100:if(jb>=0)SfEnumTools_setTo(q1,ast_GmlNodeDef_Jump(_g[2],jb,"break"));break;
				case 95:break;
				case 91:break;
				case 92:break;
				case 94:break;
				case 96:break;
				case 88:
					if(jc>=0){
						var _jb=jb;
						jb=-1;
						ast_GmlNodeTools_seek(q1,st1,fn);
						jb=_jb;
					}
					break;
				default:ast_GmlNodeTools_seek(q1,st1,fn);
			}
			return false;
		}
		fn(q,null);
	}
	if(gmcr_CrCore_needsSplit(r,null))for(var _=0;_<1;_++){
		var _g11=r;
		switch(_g11[1]){
			case 106:
				d=_g11[2];
				s=_g11[3];
				h=GmlProgram_seekScript;
				i=h.labels++;
				if(h.labelMap[s]!=null)return GmlProgram_seekInst.error("Label `"+s+"` is already defined.",d);
				h.labelMap[s]=i;
				SfEnumTools_setTo(r,ast_GmlNodeDef_Label(d,i,s));
				break;
			case 86:
				var _else=_g11[5];
				var _then=_g11[4];
				var _cond=_g11[3];
				var d3=_g11[2];
				h=GmlProgram_seekScript;
				if(gmcr_CrCore_unroll(_cond))return true;
				if(_else==null){
					if(_then[1]==107)continue;
				}
				if(gmcr_CrCore_unroll(_then))return true;
				var elseAt=h.labels++;
				var exitAt;
				if(_else!=null){
					if(gmcr_CrCore_unroll(_else))return true;
					exitAt=h.labels++;
				}else exitAt=elseAt;
				w=[ast_GmlNodeDef_IfThen(d3,ast_GmlNodeTools_invert(_cond),ast_GmlNodeDef_Jump(d3,elseAt,(_else!=null)?"else":"end if")),_then];
				if(_else!=null){
					w.push(ast_GmlNodeDef_Jump(d3,exitAt,"end if"));
					w.push(ast_GmlNodeDef_Label(d3,elseAt,"else"));
					w.push(_else);
				}
				w.push(ast_GmlNodeDef_Label(d3,exitAt,"end if"));
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d3,w));
				break;
			case 91:
				var _node1=_g11[4];
				var _cond1=_g11[3];
				var d5=_g11[2];
				h=GmlProgram_seekScript;
				var condAt=h.labels++;
				if(gmcr_CrCore_unroll(_cond1))return true;
				if(gmcr_CrCore_unroll(_node1))return true;
				var exitAt2=h.labels++;
				procLoop(_node1,condAt,exitAt2);
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d5,[ast_GmlNodeDef_Label(d5,condAt,"while"),ast_GmlNodeDef_IfThen(d5,ast_GmlNodeTools_invert(_cond1),ast_GmlNodeDef_Jump(d5,exitAt2,"end while")),_node1,ast_GmlNodeDef_Jump(d5,condAt,"while"),ast_GmlNodeDef_Label(d5,exitAt2,"end while")]));
				break;
			case 92:
				var _cond2=_g11[4];
				var _node2=_g11[3];
				var d6=_g11[2];
				h=GmlProgram_seekScript;
				var nodeAt1=h.labels++;
				if(gmcr_CrCore_unroll(_node2))return true;
				var condAt1=h.labels++;
				if(gmcr_CrCore_unroll(_cond2))return true;
				var exitAt3=h.labels++;
				procLoop(_node2,condAt1,exitAt3);
				if((r[1]==92)){
					_cond2=ast_GmlNodeTools_invert(_cond2);
					s="do until";
				}else s="do while";
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d6,[ast_GmlNodeDef_Label(d6,nodeAt1,"begin "+s),_node2,ast_GmlNodeDef_Label(d6,condAt1,"check "+s),ast_GmlNodeDef_IfThen(d6,_cond2,ast_GmlNodeDef_Jump(d6,nodeAt1)),ast_GmlNodeDef_Label(d6,exitAt3,"end "+s)]));
				break;
			case 93:
				var _cond3=_g11[4];
				var _node3=_g11[3];
				var d7=_g11[2];
				h=GmlProgram_seekScript;
				var nodeAt2=h.labels++;
				if(gmcr_CrCore_unroll(_node3))return true;
				var condAt2=h.labels++;
				if(gmcr_CrCore_unroll(_cond3))return true;
				var exitAt4=h.labels++;
				procLoop(_node3,condAt2,exitAt4);
				if((r[1]==92)){
					_cond3=ast_GmlNodeTools_invert(_cond3);
					s="do until";
				}else s="do while";
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d7,[ast_GmlNodeDef_Label(d7,nodeAt2,"begin "+s),_node3,ast_GmlNodeDef_Label(d7,condAt2,"check "+s),ast_GmlNodeDef_IfThen(d7,_cond3,ast_GmlNodeDef_Jump(d7,nodeAt2)),ast_GmlNodeDef_Label(d7,exitAt4,"end "+s)]));
				break;
			case 95:
				var _node4=_g11[6];
				var _post=_g11[5];
				var _cond4=_g11[4];
				var _init=_g11[3];
				var d8=_g11[2];
				h=GmlProgram_seekScript;
				w=[];
				if(gmcr_CrCore_unroll(_init))return true;
				var condAt3=h.labels++;
				if(gmcr_CrCore_unroll(_cond4))return true;
				if(gmcr_CrCore_unroll(_node4))return true;
				var postAt=h.labels++;
				if(gmcr_CrCore_unroll(_post))return true;
				var exitAt5=h.labels++;
				procLoop(_node4,postAt,exitAt5);
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d8,[_init,ast_GmlNodeDef_Label(d8,condAt3,"check for"),ast_GmlNodeDef_IfThen(d8,ast_GmlNodeTools_invert(_cond4),ast_GmlNodeDef_Jump(d8,exitAt5)),_node4,ast_GmlNodeDef_Label(d8,postAt,"post for"),_post,ast_GmlNodeDef_Jump(d8,condAt3),ast_GmlNodeDef_Label(d8,exitAt5,"end for")]));
				break;
			case 88:
				var _default=_g11[5];
				var _cases=_g11[4];
				var _expr=_g11[3];
				var d4=_g11[2];
				h=GmlProgram_seekScript;
				w=[null];
				var rcases=[];
				gmcr_CrCore_unroll(_expr);
				var _g13=0;
				while(_g13<_cases.length){
					var _case=_cases[_g13];
					++_g13;
					var _node=_case.expr;
					var nodeAt=h.labels++;
					var nd=_node[2];
					if(gmcr_CrCore_unroll(_node))return true;
					rcases.push({
						values:_case.values,
						expr:ast_GmlNodeDef_Jump(nd,nodeAt),
						pre:_case.pre
					});
					w.push(ast_GmlNodeDef_Label(nd,nodeAt,"case"));
					w.push(_node);
				}
				var defAt=h.labels++;
				var exitAt1;
				if(_default!=null){
					if(gmcr_CrCore_unroll(_default))return true;
					w.push(ast_GmlNodeDef_Label(d4,defAt,"default"));
					w.push(_default);
					exitAt1=h.labels++;
				}else exitAt1=defAt;
				var _g14=0;
				while(_g14<_cases.length){
					var _case1=_cases[_g14];
					++_g14;
					procLoop(_case1.expr,-1,exitAt1);
				}
				_default=ast_GmlNodeDef_Jump(d4,defAt);
				w.push(ast_GmlNodeDef_Label(d4,exitAt1,"end switch"));
				w[0]=ast_GmlNodeDef_Switch(d4,_expr,rcases,_default);
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d4,w));
				break;
			case 96:return GmlProgram_seekInst.error("Can't yield inside a with-loop.",_g11[2]);
			case 103:
				var d10=_g11[2];
				var l=GmlProgram_seekScript.labels++;
				SfEnumTools_setTo(r,ast_GmlNodeDef_Block(d10,[ast_GmlNodeDef_Yield(d10,_g11[3],l),ast_GmlNodeDef_Label(d10,l,"post yield")]));
				break;
			default:return ast_GmlNodeTools_seek(r,st,gmcr_CrCore_unroll);
		}
	}
	return false;
}
function gmcr_CrCore_procJump(r,st){
	var _g=r;
	if(_g[1]==107){
		var s=_g[3];
		var d=_g[2];
		var i=GmlProgram_seekScript.labelMap[s];
		if(i==null)return GmlProgram_seekInst.error("There is no label `"+s+"`.",d);
		SfEnumTools_setTo(r,ast_GmlNodeDef_Jump(d,i,s));
	}else return ast_GmlNodeTools_seek(r,st,gmcr_CrCore_procJump);
	return false;
}
function gmcr_CrCore_procLocal(r,st){
	var z=gmcr_CrCore_hasYield(r,st);
	GmlProgram_seekScript.hasYield=z;
	if(z){
		if(gmcr_CrCore_replaceLocal(r,st))return true;
	}
	return false;
}
function gmcr_CrCore_seek(p){
	if(p.seek(gmcr_CrCore_procLocal))return true;
	if(p.seek(gmcr_CrCore_unroll))return true;
	if(p.seek(gmcr_CrCore_procJump))return true;
	return false;
}
function gmcr_CrCore_proc(gml,opt){
	gmcr_CrCore_v2=opt.version==2;
	var post="";
	if(opt.update){
		var pos0=gml.indexOf("/*//!#gmcr");
		if(pos0<0)return {code:null,error:"If writing to the same file, original code must be contained in a `/*//!#gmcr` comment."};
		var pos1=gml.indexOf("//!#gmcr*/",pos0);
		if(pos1<0)pos1=gml.length;
		post="\r\n"+gml.substring(pos0,pos1+"//!#gmcr*/".length)+"\r\n";
		pos0+="/*//!#gmcr".length;
		if(HxOverrides_cca(gml,pos0)==13)++pos0;
		if(HxOverrides_cca(gml,pos0)==10)++pos0;
		if(HxOverrides_cca(gml,pos1-1)==10)--pos1;
		if(HxOverrides_cca(gml,pos1-1)==13)--pos1;
		gml=gml.substring(pos0,pos1);
	}
	var pg=new GmlProgram([new ast_GmlSource("",gml,"main")]);
	if(pg.errorText==null){
		return {code:GmlPrint_program(pg)+post,error:null};
	}else return {code:null,error:pg.errorText};
}
function gmcr_CrCoreNode_main(){
	window.gmcr_proc=gmcr_CrCore_proc;
}
function gml_SeekAdjfix_proc(q,st){
	var _g=q;
	switch(_g[1]){
		case 24:
			var x1=_g[3];
			var pre1=q[1]==23;
			var o1;
			var inBlock1=ast_GmlNodeTools_isInBlock(x1,st[0]);
			if(pre1||inBlock1){
				var _g13=x1;
				switch(_g13[1]){
					case 69:SfEnumTools_setTo(q,ast_GmlNodeDef_DsListPrefix(_g[2],_g13[3],_g13[4],_g[4]));break;
					case 74:SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapPrefix(_g[2],_g13[3],_g13[4],_g[4]));break;
					case 79:SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridPrefix(_g[2],_g13[3],_g13[4],_g13[5],_g[4]));break;
					case 49:SfEnumTools_setTo(q,ast_GmlNodeDef_IndexPrefix(_g[2],_g13[3],_g13[4],_g[4]));break;
					case 54:SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dPrefix(_g[2],_g13[3],_g13[4],_g13[5],_g[4]));break;
					case 59:SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdPrefix(_g[2],_g13[3],_g13[4],_g[4]));break;
					case 64:SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dPrefix(_g[2],_g13[3],_g13[4],_g13[5],_g[4]));break;
				}
			}else {
				var _g14=x1;
				switch(_g14[1]){
					case 69:SfEnumTools_setTo(q,ast_GmlNodeDef_DsListPostfix(_g[2],_g14[3],_g14[4],_g[4]));break;
					case 74:SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapPostfix(_g[2],_g14[3],_g14[4],_g[4]));break;
					case 79:SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridPostfix(_g[2],_g14[3],_g14[4],_g14[5],_g[4]));break;
					case 49:SfEnumTools_setTo(q,ast_GmlNodeDef_IndexPostfix(_g[2],_g14[3],_g14[4],_g[4]));break;
					case 54:SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dPostfix(_g[2],_g14[3],_g14[4],_g14[5],_g[4]));break;
					case 59:SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdPostfix(_g[2],_g14[3],_g14[4],_g[4]));break;
					case 64:SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dPostfix(_g[2],_g14[3],_g14[4],_g14[5],_g[4]));break;
				}
			}
			break;
		case 23:
			var x=_g[3];
			var pre=q[1]==23;
			var o;
			var inBlock=ast_GmlNodeTools_isInBlock(x,st[0]);
			if(pre||inBlock){
				var _g11=x;
				switch(_g11[1]){
					case 69:SfEnumTools_setTo(q,ast_GmlNodeDef_DsListPrefix(_g[2],_g11[3],_g11[4],_g[4]));break;
					case 74:SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapPrefix(_g[2],_g11[3],_g11[4],_g[4]));break;
					case 79:SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridPrefix(_g[2],_g11[3],_g11[4],_g11[5],_g[4]));break;
					case 49:SfEnumTools_setTo(q,ast_GmlNodeDef_IndexPrefix(_g[2],_g11[3],_g11[4],_g[4]));break;
					case 54:SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dPrefix(_g[2],_g11[3],_g11[4],_g11[5],_g[4]));break;
					case 59:SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdPrefix(_g[2],_g11[3],_g11[4],_g[4]));break;
					case 64:SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dPrefix(_g[2],_g11[3],_g11[4],_g11[5],_g[4]));break;
				}
			}else {
				var _g12=x;
				switch(_g12[1]){
					case 69:SfEnumTools_setTo(q,ast_GmlNodeDef_DsListPostfix(_g[2],_g12[3],_g12[4],_g[4]));break;
					case 74:SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapPostfix(_g[2],_g12[3],_g12[4],_g[4]));break;
					case 79:SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridPostfix(_g[2],_g12[3],_g12[4],_g12[5],_g[4]));break;
					case 49:SfEnumTools_setTo(q,ast_GmlNodeDef_IndexPostfix(_g[2],_g12[3],_g12[4],_g[4]));break;
					case 54:SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dPostfix(_g[2],_g12[3],_g12[4],_g12[5],_g[4]));break;
					case 59:SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdPostfix(_g[2],_g12[3],_g12[4],_g[4]));break;
					case 64:SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dPostfix(_g[2],_g12[3],_g12[4],_g12[5],_g[4]));break;
				}
			}
			break;
	}
	return ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
}
function gml_SeekArguments_proc(q,st){
	ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
	var _g=q;
	switch(_g[1]){
		case 13:
			var i=_g[3];
			if(GmlProgram_seekScript.arguments<=i)GmlProgram_seekScript.arguments=i+1;
			break;
		case 14:SfEnumTools_setTo(q,ast_GmlNodeDef_ArgIndex(_g[2],ast_GmlNodeTools_offset(_g[3],1)));break;
		case 15:
			var d2=_g[2];
			SfEnumTools_setTo(q,ast_GmlNodeDef_BinOp(d2,17,ast_GmlNodeDef_ArgCount(d2),ast_GmlNodeDef_Number(d2,1,null)));
			break;
	}
	return false;
}
function gml_SeekEnumFields_proc(q,st){
	if(ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc))return true;
	var _g=q;
	if(_g[1]==37){
		var f=_g[4];
		var x=_g[3];
		var d=_g[2];
		var _g1=x;
		if(_g1[1]==7){
			var s=_g1[3];
			var e=GmlProgram_seekInst.enumMap[s];
			if(e!=null){
				var c=e.ctrMap[f];
				if(c!=null){
					SfEnumTools_setTo(q,ast_GmlNodeDef_EnumCtr(d,e,c));
					return false;
				}else return GmlProgram_seekInst.error("Enum `"+s+"` does not contain field `"+f+"`",d);
			}
		}
		if(data_GmlAPI_varFlags[f]!=null){
			if((data_GmlAPI_varFlags[f]&4)==0)return GmlProgram_seekInst.error("`"+f+"` is not an instance-specific variable.",d);
		}
	}
	return false;
}
function gml_SeekEnumValues_proc(){
	var _g=0;
	var _g1=GmlProgram_seekInst.enums;
	while(_g<_g1.length){
		var e=_g1[_g];
		++_g;
		var next=0;
		var _g2=0;
		var _g3=e.ctrList;
		while(_g2<_g3.length){
			var c=_g3[_g2];
			++_g2;
			if(c.node!=null){
				var st=[];
				var _seekFunc=GmlProgram_seekFunc;
				GmlProgram_seekFunc=gml_SeekIdents_proc;
				GmlProgram_seekScript=null;
				gml_SeekIdents_proc(c.node,st);
				GmlProgram_seekFunc=_seekFunc;
				gml_SeekEval_eval(c.node);
				var v=gml_SeekEval_nodeToValue(c.node);
				if((typeof v)=="number"){
					c.value=Math.floor(v);
					next=c.value+1;
				}else if(v!=gml_SeekEval_invalidValue){
					return GmlProgram_seekInst.error("Enum values should be integer",c.node[2]);
				}else return GmlProgram_seekInst.error("Enum values should be constant",c.node[2]);
			}else c.value=next++;
		}
	}
	return false;
}
function gml_SeekEval_nodeToValue(node){
	var _g=node;
	switch(_g[1]){
		case 0:return null;
		case 1:return _g[3];
		case 2:return _g[3];
		case 12:return data_GmlAPI_constVal[_g[3]];
		default:return gml_SeekEval_invalidValue;
	}
}
function gml_SeekEval_valueToNode(val,d){
	if((typeof val)=="number"){
		return ast_GmlNodeDef_Number(d,val,null);
	}else if((typeof val)=="string"){
		return ast_GmlNodeDef_CString(d,val);
	}else if(val==null){
		return ast_GmlNodeDef_Undefined(d);
	}else return null;
}
function gml_SeekEval_proc(q,st){
	var f1, f2;
	var z=true;
	var v1, v2, i, n;
	var _g=q;
	switch(_g[1]){
		case 26:
			if(_g[3]==16){
				var b=_g[5];
				var a=_g[4];
				var d=_g[2];
				if(gml_SeekEval_proc(a,st))z=false;
				if(gml_SeekEval_proc(b,st))z=false;
				if(z){
					v1=gml_SeekEval_nodeToValue(a);
					v2=gml_SeekEval_nodeToValue(b);
					if((typeof v1)=="string"){
						if((typeof v2)=="string"){
							SfEnumTools_setTo(q,ast_GmlNodeDef_CString(d,v1+v2));
						}else {
							var _g1=b;
							if(_g1[1]==26){
								if(_g1[3]==16){
									var _hx_tmp=_g1[4];
									if(_hx_tmp[1]==2){
										SfEnumTools_setTo(q,ast_GmlNodeDef_BinOp(d,16,ast_GmlNodeDef_CString(d,v1+_hx_tmp[3]),_g1[5]));
									}else {
										gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
										gml_SeekEval_errorPos=q[2];
										z=false;
									}
								}else {
									gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
									gml_SeekEval_errorPos=q[2];
									z=false;
								}
							}else {
								gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
								gml_SeekEval_errorPos=q[2];
								z=false;
							}
						}
					}else if((typeof v1)=="number"){
						if((typeof v2)=="number"){
							SfEnumTools_setTo(q,ast_GmlNodeDef_Number(d,v1+v2,null));
						}else {
							gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
							gml_SeekEval_errorPos=q[2];
							z=false;
						}
					}else if((typeof v2)=="string"){
						var _g2=a;
						if(_g2[1]==26){
							if(_g2[3]==16){
								var _hx_tmp1=_g2[5];
								if(_hx_tmp1[1]==2){
									SfEnumTools_setTo(q,ast_GmlNodeDef_BinOp(d,16,_g2[4],ast_GmlNodeDef_CString(d,_hx_tmp1[3]+v2)));
								}else {
									gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
									gml_SeekEval_errorPos=q[2];
									z=false;
								}
							}else {
								gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
								gml_SeekEval_errorPos=q[2];
								z=false;
							}
						}else {
							gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
							gml_SeekEval_errorPos=q[2];
							z=false;
						}
					}else {
						gml_SeekEval_errorText="Can't add "+a[0]+" and "+b[0]+" at compile time";
						gml_SeekEval_errorPos=q[2];
						z=false;
					}
				}
			}else {
				var b1=_g[5];
				var a1=_g[4];
				var d1=_g[2];
				var o=_g[3];
				if(gml_SeekEval_proc(a1,st))z=false;
				if(gml_SeekEval_proc(b1,st))z=false;
				if(z){
					v1=gml_SeekEval_nodeToValue(a1);
					v2=gml_SeekEval_nodeToValue(b1);
					if((typeof v1)=="number"&&(typeof v2)=="number"){
						f1=v1;
						f2=v2;
						switch(o){
							case 16:f1+=f2;break;
							case 17:f1-=f2;break;
							case 0:f1*=f2;break;
							case 1:f1/=f2;break;
							case 2:f1%=f2;break;
							case 3:f1=f1/(f2|0)|0;break;
							case 49:f1=(f1|0)&(f2|0);break;
							case 48:f1=f1|0|(f2|0);break;
							case 50:f1=(f1|0)^(f2|0);break;
							case 32:f1=(f1|0)<<(f2|0);break;
							case 33:f1=(f1|0)>>(f2|0);break;
							case 64:f1=(f1==f2)?1:0;break;
							case 65:f1=(f1!=f2)?1:0;break;
							case 67:f1=(f1<=f2)?1:0;break;
							case 69:f1=(f1>=f2)?1:0;break;
							case 66:f1=(f1<f2)?1:0;break;
							case 68:f1=(f1>f2)?1:0;break;
							case 80:f1=(f1>0.5&&f2>0.5)?1:0;break;
							case 96:f1=(f1>0.5||f2>0.5)?1:0;break;
							default:
								gml_SeekEval_errorText="Can't apply "+ast__GmlOp_GmlOp_Impl__getName(o);
								gml_SeekEval_errorPos=q[2];
								z=false;
						}
						if(z)SfEnumTools_setTo(q,ast_GmlNodeDef_Number(d1,f1,null));
					}else {
						gml_SeekEval_errorText="Can't apply "+ast__GmlOp_GmlOp_Impl__getName(o)+" to "+a1[0]+" and "+b1[0];
						gml_SeekEval_errorPos=q[2];
						z=false;
					}
				}
			}
			break;
		case 0:break;
		case 1:break;
		case 2:break;
		case 12:break;
		case 21:
			var args=_g[4];
			n=args.length;
			for(i=0;i<n;++i)if(gml_SeekEval_proc(args[i],st))z=false;
			break;
		default:
			if(gml_SeekEval_evalRec){
				if(ast_GmlNodeTools_seek(q,st,gml_SeekEval_proc))z=false;
			}else {
				gml_SeekEval_errorText=q[0]+" doesn't seem to be a constant expression.";
				gml_SeekEval_errorPos=q[2];
				z=false;
			}
	}
	return !z;
}
function gml_SeekEval_eval(q){
	gml_SeekEval_evalRec=false;
	return gml_SeekEval_proc(q,null);
}
function gml_SeekEval_opt(){
	gml_SeekEval_evalRec=true;
	GmlProgram_seekInst.seek(gml_SeekEval_proc);
	return false;
}
function gml_SeekFields_proc(q,st){
	var _g=q;
	if(_g[1]==37){
		var s=_g[4];
		var x=_g[3];
		var d=_g[2];
		if(x[1]==10)SfEnumTools_setTo(q,ast_GmlNodeDef_Global(d,s));
	}
	return ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
}
function gml_SeekIdents_proc(q,st){
	var _g=q;
	if(_g[1]==7){
		var s=_g[3];
		var d=_g[2];
		var scr=GmlProgram_seekScript;
		if(scr!=null&&scr.namedArgs[s]!=null){
			SfEnumTools_setTo(q,ast_GmlNodeDef_ArgConst(d,scr.namedArgs[s]));
		}else if(scr!=null&&scr.localMap[s]!=null){
			SfEnumTools_setTo(q,ast_GmlNodeDef_Local(d,s));
		}else if(GmlProgram_seekInst.macros[s]!=null){
			SfEnumTools_setTo(q,ast_GmlNodeTools_clone(GmlProgram_seekInst.macros[s]));
			gml_SeekIdents_proc(q,st);
		}else if(data_GmlAPI_constMap[s]!=null){
			SfEnumTools_setTo(q,ast_GmlNodeDef_Const(d,s));
		}else if(data_GmlAPI_varFlags[s]!=null){
			SfEnumTools_setTo(q,ast_GmlNodeDef_Env(d,s));
			if(st.length>0){
				var _g1=st[0];
				switch(_g1[1]){
					case 49:if((data_GmlAPI_varFlags[s]&2)!=0){
						SfEnumTools_setTo(st[0],ast_GmlNodeDef_Env1d(_g1[2],s,_g1[4]));
					}else return GmlProgram_seekInst.error("`"+s+"` is not an array.",_g1[2]);break;
					case 54:return GmlProgram_seekInst.error("`"+s+"` is not a 2d array.",_g1[2]);
					default:if((data_GmlAPI_varFlags[s]&2)!=0)SfEnumTools_setTo(q,ast_GmlNodeDef_Env1d(d,s,ast_GmlNodeDef_Number(d,0,null)));
				}
			}
		}else if(GmlProgram_seekInst.scriptMap[s]!=null)SfEnumTools_setTo(q,ast_GmlNodeDef_Script(d,GmlProgram_seekInst.scriptMap[s]));
	}
	return ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
}
function gml_SeekLocals_proc(q,st){
	var _g=q;
	if(_g[1]==84){
		var s=_g[3];
		var d=_g[2];
		if(GmlProgram_seekScript.localMap[s]==null)GmlProgram_seekScript.localMap[s]=GmlProgram_seekScript.locals++;
	}
	return ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
}
function gml_SeekMergeBlocks_proc(q,st){
	ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
	var _g=q;
	if(_g[1]==85){
		var w=_g[3];
		for(var i=0;i<w.length;++i){
			var _g1=w[i];
			if(_g1[1]==85){
				var w2=_g1[3];
				w.splice(i,1);
				var k=w2.length;
				while(--k>=0){
					w.splice(i,0,w2[k]);
				}
			}
		}
	}
	return false;
}
function gml_SeekRepeat_proc(q,st){
	ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
	var _g=q;
	if(_g[1]==94){
		var x=_g[4];
		var t=_g[3];
		var d=_g[2];
		if(!gmcr_CrCore_needsSplit(q,null))return false;
		var ind=0;
		var _g1=0;
		while(_g1<st.length){
			var sx=st[_g1];
			++_g1;
			if(sx[1]==94)++ind;
		}
		var v="__repeat";
		if(ind>0)v+=ind;
		if(GmlProgram_seekScript.localMap[v]==null)GmlProgram_seekScript.localMap[v]=GmlProgram_seekScript.locals++;
		SfEnumTools_setTo(q,ast_GmlNodeDef_For(d,ast_GmlNodeDef_VarDecl(d,v,t),ast_GmlNodeDef_BinOp(d,69,ast_GmlNodeDef_Local(d,v),ast_GmlNodeDef_Number(d,1,null)),ast_GmlNodeDef_SetOp(d,17,ast_GmlNodeDef_Local(d,v),ast_GmlNodeDef_Number(d,1,null)),x));
	}
	return false;
}
function gml_SeekSetOp_resolveSetOp_rfn(q,st){
	var _g=q;
	switch(_g[1]){
		case 51:
			if(ast_GmlNodeTools_equals(gml_SeekSetOp_resolveSetOp_xw,_g[3])){
				gml_SeekSetOp_resolveSetOp_safe=true;
				return true;
			}
			break;
		case 55:
			if(ast_GmlNodeTools_equals(gml_SeekSetOp_resolveSetOp_xw,_g[3])){
				gml_SeekSetOp_resolveSetOp_safe=true;
				return true;
			}
			break;
		case 56:
			if(ast_GmlNodeTools_equals(gml_SeekSetOp_resolveSetOp_xw,_g[3])){
				gml_SeekSetOp_resolveSetOp_safe=true;
				return true;
			}
			break;
		case 50:
			if(ast_GmlNodeTools_equals(gml_SeekSetOp_resolveSetOp_xw,_g[3])){
				gml_SeekSetOp_resolveSetOp_safe=true;
				return true;
			}
			break;
		case 27:
			if(ast_GmlNodeTools_equals(gml_SeekSetOp_resolveSetOp_xw,_g[4])){
				gml_SeekSetOp_resolveSetOp_safe=_g[5][1]==4;
				return true;
			}
			break;
	}
	return ast_GmlNodeTools_seekAll(q,st,gml_SeekSetOp_resolveSetOp_rfn);
}
function gml_SeekSetOp_proc(q,st){
	var _g=q;
	if(_g[1]==27){
		var v=_g[5];
		var x=_g[4];
		var o=_g[3];
		var d=_g[2];
		var _g1=ast_GmlNodeTools_unpack(x);
		switch(_g1[1]){
			case 31:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_LocalAop(d,_g1[3],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_LocalSet(d,_g1[3],v));break;
			case 34:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_GlobalAop(d,_g1[3],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_GlobalSet(d,_g1[3],v));break;
			case 13:break;
			case 14:break;
			case 37:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_FieldAop(d,_g1[3],_g1[4],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_FieldSet(d,_g1[3],_g1[4],v));break;
			case 49:
				var xw=_g1[3];
				var xd3=_g1[2];
				var _g2=x;
				switch(_g2[1]){
					case 49:if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_IndexAop(xd3,xw,_g2[4],o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_IndexSet(xd3,xw,_g2[4],v));break;
					case 54:if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dAop(xd3,xw,_g2[4],_g2[5],o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dSet(xd3,xw,_g2[4],_g2[5],v));break;
				}
				gml_SeekSetOp_resolveSetOp_safe=false;
				gml_SeekSetOp_resolveSetOp_xw=xw;
				ast_GmlNodeTools_seekAllOut(q,st,gml_SeekSetOp_resolveSetOp_rfn,0);
				if(!gml_SeekSetOp_resolveSetOp_safe)SfEnumTools_setTo(q,ast_GmlNodeDef_Block(xd3,[ast_GmlNodeDef_EnsureArray(xd3,ast_GmlNodeTools_clone(xw)),ast_GmlNodeTools_clone(q)]));
				break;
			case 54:
				var xw1=_g1[3];
				var xd4=_g1[2];
				var _g3=x;
				switch(_g3[1]){
					case 49:if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_IndexAop(xd4,xw1,_g3[4],o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_IndexSet(xd4,xw1,_g3[4],v));break;
					case 54:if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dAop(xd4,xw1,_g3[4],_g3[5],o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_Index2dSet(xd4,xw1,_g3[4],_g3[5],v));break;
				}
				gml_SeekSetOp_resolveSetOp_safe=false;
				gml_SeekSetOp_resolveSetOp_xw=xw1;
				ast_GmlNodeTools_seekAllOut(q,st,gml_SeekSetOp_resolveSetOp_rfn,0);
				if(!gml_SeekSetOp_resolveSetOp_safe)SfEnumTools_setTo(q,ast_GmlNodeDef_Block(xd4,[ast_GmlNodeDef_EnsureArray(xd4,ast_GmlNodeTools_clone(xw1)),ast_GmlNodeTools_clone(q)]));
				break;
			case 40:
				var s3=_g1[3];
				var f=data_GmlAPI_varFlags[s3];
				if((f&1)==0){
					if((f&2)!=0){
						var k=ast_GmlNodeDef_Number(d,0,null);
						if(o!=-1){
							SfEnumTools_setTo(q,ast_GmlNodeDef_Env1dAop(d,s3,k,o,v));
						}else SfEnumTools_setTo(q,ast_GmlNodeDef_Env1dSet(d,s3,k,v));
					}else if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_EnvAop(d,s3,o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_EnvSet(d,s3,v));
				}else return GmlProgram_seekInst.error("`"+s3+"` is read-only",_g1[2]);
				break;
			case 43:
				var s4=_g1[4];
				if((data_GmlAPI_varFlags[s4]&1)==0){
					if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_EnvFdAop(d,_g1[3],s4,o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_EnvFdSet(d,_g1[3],s4,v));
				}else return GmlProgram_seekInst.error("`"+s4+"` is read-only",_g1[2]);
				break;
			case 46:
				var s5=_g1[3];
				if((data_GmlAPI_varFlags[s5]&1)==0){
					if(o!=-1){
						SfEnumTools_setTo(q,ast_GmlNodeDef_Env1dAop(d,s5,_g1[4],o,v));
					}else SfEnumTools_setTo(q,ast_GmlNodeDef_Env1dSet(d,s5,_g1[4],v));
				}else return GmlProgram_seekInst.error("`"+s5+"` is read-only",_g1[2]);
				break;
			case 69:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_DsListAop(d,_g1[3],_g1[4],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_DsListSet(d,_g1[3],_g1[4],v));break;
			case 74:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapAop(d,_g1[3],_g1[4],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_DsMapSet(d,_g1[3],_g1[4],v));break;
			case 79:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridAop(d,_g1[3],_g1[4],_g1[5],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_DsGridSet(d,_g1[3],_g1[4],_g1[5],v));break;
			case 59:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdAop(d,_g1[3],_g1[4],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_RawIdSet(d,_g1[3],_g1[4],v));break;
			case 64:if(o!=-1){
				SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dAop(d,_g1[3],_g1[4],_g1[5],o,v));
			}else SfEnumTools_setTo(q,ast_GmlNodeDef_RawId2dSet(d,_g1[3],_g1[4],_g1[5],v));break;
			default:return GmlProgram_seekInst.error("Expression is not settable",x[2]);
		}
	}
	return ast_GmlNodeTools_seek(q,st,GmlProgram_seekFunc);
}
function haxe_ds_IntMap(){
	this.h={};
}
function js__Boot_HaxeError_wrap(val){
	if((val instanceof Error)){
		return val;
	}else return new js__Boot_HaxeError(val);
}
function js__Boot_HaxeError(val){
	Error.call(this);
	this.val=val;
	if(Error.captureStackTrace)Error.captureStackTrace(this,js__Boot_HaxeError);
}
sfjs_extend(js__Boot_HaxeError,Error,{});
function js_Boot___string_rec(o,s){
	if(o==null)return "null";
	if(s.length>=5)return "<...>";
	var t=(typeof o);
	if(t=="function"&&(o.__name__||o.__ename__))t="object";
	switch(t){
		case "object":
			if(o.__enum__){
				var e=$hxEnums[o.__enum__];
				var n=e.__constructs__[o._hx_index];
				var con=e[n];
				if(con.__params__){
					s+="\t";
					var tmp=n+"(";
					var _g=[];
					var _g1=0;
					var _g2=con.__params__;
					while(_g1<_g2.length){
						var p=_g2[_g1];
						++_g1;
						_g.push(js_Boot___string_rec(o[p],s));
					}
					return tmp+_g.join(",")+")";
				}else return n;
			}
			if((o instanceof Array)){
				var l=o.length;
				var i;
				var str="[";
				s+="\t";
				var i1=0;
				for(var _g3=l;i1<_g3;i1++)str+=((i1>0)?",":"")+js_Boot___string_rec(o[i1],s);
				str+="]";
				return str;
			}
			var tostr;
			try{
				tostr=o.toString;
			}catch(e1){
				var e2=((e1 instanceof js__Boot_HaxeError))?e1.val:e1;
				return "???";
			}
			if(tostr!=null&&tostr!=Object.toString&&(typeof tostr)=="function"){
				var s2=o.toString();
				if(s2!="[object Object]")return s2;
			}
			var k=null;
			var str1="{\n";
			s+="\t";
			var hasp=o.hasOwnProperty!=null;
			for( var k in o ) {;
			if(hasp&&!o.hasOwnProperty(k))continue;
			if(k=="prototype"||k=="__class__"||k=="__super__"||k=="__interfaces__"||k=="__properties__")continue;
			if(str1.length!=2)str1+=", \n";
			str1+=s+k+" : "+js_Boot___string_rec(o[k],s);
			};
			s=s.substring(1);
			str1+="\n"+s+"}";
			return str1;
		case "function":return "<function>";
		case "string":return o;
		default:return String(o);
	}
}
function tools_GmlBuffer(){
	this.semicoAfter=-1;
	this.indent=0;
	StringBuf.call(this);
}
sfjs_extend(tools_GmlBuffer,StringBuf,{
	addLine:function(){
		this.b+="\r";
		this.b+="\n";
		var k=this.indent;
		while(--k>=0){
			this.b+="\t";
		}
	},
	addHint:function(s){
		if(s!=null&&s!=""){
			this.b+="/* ";
			this.b+=(s==null)?"null":""+s;
			this.b+=" */";
		}
	}
});
Object.defineProperty(js__Boot_HaxeError.prototype,"message",{get:function(){
	return String(this.val);
}});
var GmlParser_errorText;
var GmlParser_errorPos;
var GmlParser_temRow;
var GmlParser_temRowStart;
var GmlParser_temEnd;
var GmlPrint_printProgram=null;
var GmlPrint_printScript=null;
var GmlPrint_self="gml$self";
var GmlPrint_other="gml$other";
var GmlPrint_withDepth=0;
var GmlPrint_crLabelId=-1;
var GmlPrint_crReplaceList=[];
var GmlPrint_crReplaceMap=new haxe_ds_IntMap();
var GmlProgram_seekInst;
var GmlProgram_seekFunc;
var GmlProgram_seekScript;
var data_GmlAPI_varFlags=Object.create(null);
var data_GmlAPI_constMap=Object.create(null);
var data_GmlAPI_constVal=Object.create(null);
var data_GmlAPI_instData=Object.create(null);
var data_GmlAPI_withFunc=null;
var data_GmlAPI_assetIndex=Object.create(null);
var gmcr_CrCore_v2=false;
var gml_SeekEval_errorText;
var gml_SeekEval_errorPos;
var gml_SeekEval_evalRec;
var gml_SeekEval_invalidValue=[];
var gml_SeekSetOp_resolveSetOp_safe;
var gml_SeekSetOp_resolveSetOp_xw;
gmcr_CrCoreNode_main();
})();
// Generated at 2018-08-17 15:18:20 (8239ms)
