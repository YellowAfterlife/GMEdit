package tools;

/**
	Generic result type which may hold either desired data or an error.
**/
enum Result<T, E> {
	Ok(data:T);
	Err(err:E);
}
