package ru.alfabank.skillbox.examples.https.server.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.client.OAuth2AuthorizedClientManager;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.alfabank.skillbox.examples.https.server.dto.Response;
import ru.alfabank.skillbox.examples.https.server.service.RestService;

import javax.validation.constraints.NotEmpty;

@RestController
@Validated
@RequestMapping(value = "/api/gateway/json",
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class ClientController {

    private final OAuth2AuthorizedClientManager authorizedClientManager;
    private final RestService restService;

    @PostMapping("/save")
    public ResponseEntity<Response> validateAndSave(@RequestBody @NotEmpty String rawJson) {
        var restResponse = restService.invokeSave(rawJson);
        return ResponseEntity.ok(Response.builder()
                .status(HttpStatus.OK.name())
                .body(restResponse)
                .build());
    }

    @GetMapping("/find")
    public ResponseEntity<Response> findById(@RequestParam("id") String id) {
        var restResponse = restService.invokeFind(id);
        return ResponseEntity.ok(Response.builder()
                .status(HttpStatus.OK.name())
                .body(restResponse)
                .build());
    }
}
