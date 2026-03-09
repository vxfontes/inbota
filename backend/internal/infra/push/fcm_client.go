package push

import (
	"context"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

type FCMClient struct {
	app *firebase.App
}

func NewFCMClient(credentialsJSON string) (*FCMClient, error) {
	if credentialsJSON == "" {
		return nil, fmt.Errorf("FCM credentials JSON is empty")
	}

	var opts []option.ClientOption
	if credentialsJSON[0] == '{' {
		opts = append(opts, option.WithCredentialsJSON([]byte(credentialsJSON)))
	} else {
		opts = append(opts, option.WithCredentialsFile(credentialsJSON))
	}

	app, err := firebase.NewApp(context.Background(), nil, opts...)
	if err != nil {
		return nil, fmt.Errorf("error initializing firebase app: %v", err)
	}

	return &FCMClient{app: app}, nil
}

func (c *FCMClient) Send(ctx context.Context, token, title, body string, data map[string]string) error {
	client, err := c.app.Messaging(ctx)
	if err != nil {
		return err
	}

	message := &messaging.Message{
		Token: token,
		Notification: &messaging.Notification{
			Title: title,
			Body:  body,
		},
		Data: data,
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Sound: "default",
				},
			},
		},
	}

	_, err = client.Send(ctx, message)
	return err
}

func IsTokenInvalid(err error) bool {
	return messaging.IsRegistrationTokenNotRegistered(err) || messaging.IsUnregistered(err)
}
