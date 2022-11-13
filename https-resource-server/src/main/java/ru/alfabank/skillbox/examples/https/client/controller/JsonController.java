package ru.alfabank.skillbox.examples.https.client.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import ru.alfabank.skillbox.examples.https.client.dto.JsonStateResponse;
import ru.alfabank.skillbox.examples.https.client.services.JsonService;

import javax.validation.constraints.NotEmpty;

@RestController
@Validated
@RequestMapping(value = "/json",
        consumes = MediaType.APPLICATION_JSON_VALUE,
        produces = MediaType.APPLICATION_JSON_VALUE)
@RequiredArgsConstructor
public class JsonController {

    private final JsonService jsonService;

    @PostMapping("/save")
    public ResponseEntity<JsonStateResponse> validateAndSave(@RequestBody @NotEmpty String rawJson) {
        return ResponseEntity.ok(jsonService.validateAndSave(rawJson));
    }

    @GetMapping("/find")
    public ResponseEntity<JsonStateResponse> getJson(@RequestParam("id") @ValidId String id) {
        return ResponseEntity.ok(jsonService.find(Long.valueOf(id)));
    }
}
