package tink.core;

using tink.CoreApi;

abstract Promise<T>(Surprise<T, Error>) from Surprise<T, Error> to Surprise<T, Error> {
  
  public inline function map<R>(f:Outcome<T, Error>->R):Future<R>
    return this.map(f);

  public inline function flatMap<R>(f:Outcome<T, Error>->Future<R>):Future<R>
    return this.flatMap(f);

  public inline function recover(f:Recover<T>):Future<T>
    return this.flatMap(function (o) return switch o {
      case Success(d): Future.sync(d);
      case Failure(e): f(e);
    });
        
  public inline function handle(cb:Callback<Outcome<T, Error>>):CallbackLink
    return this.handle(cb);
    
  @:to public function noise():Promise<Noise>
    return (this:Promise<T>).next(function (v) return Noise);
    
  public function next<R>(f:Next<T, R>):Promise<R> 
    return this >> function (result:T) return (f(result) : Surprise<R, Error>);
  
  @:from static function ofSpecific<T, E>(s:Surprise<T, TypedError<E>>):Promise<T>
    return (s : Surprise<T, Error>);
    
  @:from static inline function ofFuture<T>(f:Future<T>):Promise<T>
    return f.map(Success);
    
  @:from static inline function ofOutcome<T>(o:Outcome<T, Error>):Promise<T>
    return Future.sync(o);
    
  @:from static inline function ofError<T>(e:Error):Promise<T>
    return ofOutcome(Failure(e));

  @:from static inline function ofData<T>(d:T):Promise<T>
    return ofOutcome(Success(d));
    
  @:from static public function ofMany<T>(a:Array<Promise<T>>):Promise<Array<T>> {
    
    function loop(index:Int):Promise<Array<T>>
      return 
        if (index == a.length) [];
        else
          a[index].next(
            function (head) return loop(index+1).next(
              function (tail) return [head].concat(tail)
            )
          );

    return loop(0);
  }

  @:noUsing 
  static public inline function lift<T>(p:Promise<T>)
    return p;
}

@:callable
abstract Next<In, Out>(In->Promise<Out>) from In->Promise<Out> {
      
  @:from static function ofSafe<In, Out>(f:In->Outcome<Out, Error>):Next<In, Out> 
    return function (x) return f(x);
    
  @:from static function ofSync<In, Out>(f:In->Future<Out>):Next<In, Out> 
    return function (x) return f(x);
    
  @:from static function ofSafeSync<In, Out>(f:In->Out):Next<In, Out> 
    return function (x) return f(x);
    
  @:op(a * b) static function _chain<A, B, C>(a:Next<A, B>, b:Next<B, C>):Next<A, C>
    return function (v) return a(v).next(b);
  
}

@:callable
abstract Recover<T>(Error->Future<T>) from Error->Future<T> {
  @:from static function ofSync<T>(f:Error->T):Recover<T>
    return function (e) return Future.sync(f(e));
}