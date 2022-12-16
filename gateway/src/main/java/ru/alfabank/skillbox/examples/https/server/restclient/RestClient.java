package ru.alfabank.skillbox.examples.https.server.restclient;

import org.springframework.http.RequestEntity;

import java.util.function.Function;

public interface RestClient {

    <Req, Res> Res invoke(Class<Res> responseType, Function<String, RequestEntity<Req>> requestFactory);

}
