package ru.alfabank.skillbox.examples.https.server.config;

@FunctionalInterface
public interface OAuth2AuthorizedClientAccessTokenExtractor {
    String getToken(String registrationId, String clientId);
}
