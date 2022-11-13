package ru.alfabank.skillbox.examples.https.server.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.client.OAuth2AuthorizeRequest;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClient;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.security.oauth2.core.OAuth2AccessToken;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.validation.constraints.NotEmpty;

@RestController
@Validated
@RequestMapping(value = "/api/gateway/json",
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE)
//@RequiredArgsConstructor
public class ClientController {

    @Autowired
    private OAuth2AuthorizedClientManager authorizedClientManager;
//    private final JsonService jsonService;

    @PostMapping("/save")
    public ResponseEntity<String> validateAndSave(@RequestBody @NotEmpty String rawJson) {
        return ResponseEntity.ok().build();
    }

    @GetMapping("/find")
    public ResponseEntity<String> getJson(@RequestParam("id") String id) {
        return ResponseEntity.ok().build();
    }

    @GetMapping("/")
    public ResponseEntity<String> index(Authentication authentication,
                        HttpServletRequest servletRequest,
                        HttpServletResponse servletResponse) {

        OAuth2AuthorizeRequest authorizeRequest = OAuth2AuthorizeRequest.withClientRegistrationId("httpsClient")
                .principal("https-client")
                .attributes(attrs -> {
                    attrs.put(HttpServletRequest.class.getName(), servletRequest);
                    attrs.put(HttpServletResponse.class.getName(), servletResponse);
                })
                .build();
        OAuth2AuthorizedClient authorizedClient = this.authorizedClientManager.authorize(authorizeRequest);

        OAuth2AccessToken accessToken = authorizedClient.getAccessToken();

        return ResponseEntity.ok(accessToken.getTokenValue());
    }
}
