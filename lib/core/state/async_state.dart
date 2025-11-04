sealed class AsyncState<T> {}

class AsyncInitial<T> extends AsyncState<T> {}

class AsyncLoading<T> extends AsyncState<T> {}

class AsyncSuccess<T> extends AsyncState<T> {
  final T data;

  AsyncSuccess(this.data);
}

class AsyncError<T> extends AsyncState<T> {
  final String message;

  AsyncError(this.message);
}
