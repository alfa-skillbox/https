package ru.alfabank.skillbox.examples.https.server.restclient;

import lombok.RequiredArgsConstructor;
import lombok.Setter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.RequestEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;
import ru.alfabank.skillbox.examples.https.server.config.OAuth2AuthorizedClientAccessTokenExtractor;

import java.util.function.Function;

@Slf4j
@Setter
@Component
@RequiredArgsConstructor
public class ClientCredentialsRestClient implements RestClient {
    private final RestTemplate restTemplate;
    private final OAuth2AuthorizedClientAccessTokenExtractor accessTokenExtractor;

    @Value("${spring.security.oauth2.client.registration.gateway.registrationId}")
    private String registrationId;
    @Value("${spring.security.oauth2.client.registration.gateway.client-id}")
    private String clientId;

    @Override
    public <Req, Res> Res invoke(Class<Res> responseType, Function<String, RequestEntity<Req>> requestFactory) {
        String accessToken = accessTokenExtractor.getToken(registrationId, clientId);
        try {
            return getResponse(responseType, requestFactory, accessToken);
        } catch (HttpClientErrorException.Unauthorized e) {
            // 401 response returned
            log.error("401 occur! {}", e.getLocalizedMessage());
            // get new access_token
            accessToken = accessTokenExtractor.getToken(registrationId, clientId);
            // repeat exchange
            return getResponse(responseType, requestFactory, accessToken);
        } catch (HttpStatusCodeException hsce) {
            // HTTP 4xx is received
            log.error("1xx - 5xx! {}", hsce.getLocalizedMessage());
            throw hsce;
        } catch (RestClientException rce) {
            // Other cases
            log.error("Some exception occur during rest connection! {}", rce.getLocalizedMessage());
            throw rce;
        }
    }

    private <Req, Res> Res getResponse(Class<Res> responseType,
                                       Function<String, RequestEntity<Req>> requestFactory,
                                       String accessToken) {
        return restTemplate.exchange(requestFactory.apply(accessToken), responseType).getBody();
    }
}
