package ru.alfabank.skillbox.examples.https.client.converters;

import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import ru.alfabank.skillbox.examples.https.client.dto.JsonStateResponse;
import ru.alfabank.skillbox.examples.https.client.services.validation.JsonValidationResponse;

import java.util.ArrayList;

@Component
public class ValidationToStateResponseConverter {

    @NonNull
    public JsonStateResponse convert(JsonValidationResponse jsonValidationResponse) {
        return JsonStateResponse.builder()
                .isValid(jsonValidationResponse.isValid())
                .errors(new ArrayList<>(jsonValidationResponse.getErrors()))
                .build();
    }
}
