package ru.alfabank.skillbox.examples.https.server.services;

import lombok.RequiredArgsConstructor;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;
import ru.alfabank.skillbox.examples.https.server.converters.EntityToStateResponseConverter;
import ru.alfabank.skillbox.examples.https.server.converters.ValidationToStateResponseConverter;
import ru.alfabank.skillbox.examples.https.server.dto.JsonStateResponse;
import ru.alfabank.skillbox.examples.https.server.persistance.JsonEntity;
import ru.alfabank.skillbox.examples.https.server.persistance.JsonRepository;
import ru.alfabank.skillbox.examples.https.server.services.validation.JsonValidationService;

@Service
@RequiredArgsConstructor
public class JsonService {

    private final JsonValidationService validationService;
    private final JsonRepository repository;
    private final ValidationToStateResponseConverter validationToStateConverter;
    private final EntityToStateResponseConverter entityToStateResponseConverter;

    @NonNull
    @Transactional(isolation = Isolation.SERIALIZABLE)
    public JsonStateResponse validateAndSave(String json) {
        var validationResponse = validationService.validate(json);
        if (validationResponse.isValid()) {
            JsonEntity saving = new JsonEntity();
            saving.setJson(json);
            JsonEntity saved = repository.save(saving);
            repository.flush();
            return entityToStateResponseConverter.convert(saved);
        }
        return validationToStateConverter.convert(validationResponse);
    }

    public JsonStateResponse find(Long id) {
        return repository.findById(id)
                .map(entityToStateResponseConverter::convert)
                .orElseGet(() -> JsonStateResponse.builder().build());
    }
}
