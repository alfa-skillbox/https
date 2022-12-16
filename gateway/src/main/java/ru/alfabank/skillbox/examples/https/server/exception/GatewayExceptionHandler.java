package ru.alfabank.skillbox.examples.https.server.exception;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.Nullable;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import org.springframework.web.util.WebUtils;
import ru.alfabank.skillbox.examples.https.server.dto.Response;

@ControllerAdvice
public class GatewayExceptionHandler extends ResponseEntityExceptionHandler {

    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, @Nullable Object body, HttpHeaders headers, HttpStatus status, WebRequest request) {

        if (HttpStatus.INTERNAL_SERVER_ERROR.equals(status)) {
            request.setAttribute(WebUtils.ERROR_EXCEPTION_ATTRIBUTE, ex, WebRequest.SCOPE_REQUEST);
        }
        return ResponseEntity.ok(Response.builder()
                .status(status.name())
                .body(body)
                .error(Response.Error.builder()
                        .code(status.toString())
                        .message(ex.getLocalizedMessage())
                        .build())
                .build());
    }

    @ExceptionHandler(Exception.class)
    protected ResponseEntity<Object> handleException(Exception ex) {

        return ResponseEntity.ok(Response.builder()
                .status(HttpStatus.INTERNAL_SERVER_ERROR.name())
                .error(Response.Error.builder()
                        .message(ex.getLocalizedMessage())
                        .build())
                .build());
    }
}
