package ru.alfabank.skillbox.examples.https.server.config;

import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.core.OAuth2AccessToken;

@FunctionalInterface
public interface OAuth2AuthorizedClientAccessTokenExtractor {
    OAuth2AccessToken getToken(String clientName, String clientId);
}
