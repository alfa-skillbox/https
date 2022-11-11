package ru.alfabank.skillbox.examples.https.client.converters;

import org.springframework.lang.NonNull;
import org.springframework.stereotype.Component;
import ru.alfabank.skillbox.examples.https.client.dto.JsonStateResponse;
import ru.alfabank.skillbox.examples.https.client.persistance.JsonEntity;

@Component
public class EntityToStateResponseConverter {

    @NonNull
    public JsonStateResponse convert(JsonEntity entity) {
        return JsonStateResponse.builder()
                .json(entity.getJson())
                .isValid(true)
                .id(String.valueOf(entity.getId()))
                .build();
    }
}
