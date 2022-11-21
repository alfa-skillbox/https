package ru.alfabank.skillbox.examples.https.server.services.validation;

import com.fasterxml.jackson.databind.ObjectMapper;
import feign.FeignException;
import feign.Response;
import feign.codec.DecodeException;
import feign.codec.ErrorDecoder;
import lombok.SneakyThrows;
import org.springframework.http.HttpStatus;

public class RestJsonFeignClientErrorDecoder implements ErrorDecoder {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    @SneakyThrows
    @Override
    public Exception decode(String methodKey, Response response) {
        FeignException exception = FeignException.errorStatus(methodKey, response);
        Exception result = new DecodeException(response.status(),
                exception.getMessage(),
                response.request(),
                exception);

        if (HttpStatus.BAD_REQUEST.value() == response.status()) {

            result = new NotFoundDecodeException(response.status(),
                    exception.getMessage(),
                    response.request(),
                    exception,
                    MAPPER.readValue(exception.contentUTF8(), JsonValidationResponse.class));
        }
        return result;
    }
}
