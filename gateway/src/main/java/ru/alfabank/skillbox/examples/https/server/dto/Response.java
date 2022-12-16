package ru.alfabank.skillbox.examples.https.server.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class Response {
    private String status;
    private Object body;

    private Error error;

    @Data
    @Builder
    public static class Error {
        private String code;
        private String message;
    }
}
