package usecase

import (
	"context"

	"inbota/backend/internal/app/domain"
	"inbota/backend/internal/app/repository"
)

type FlagUsecase struct {
	Flags repository.FlagRepository
}

func (uc *FlagUsecase) Create(ctx context.Context, userID, name string, color *string, sortOrder *int) (domain.Flag, error) {
	name = normalizeString(name)
	if userID == "" || name == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	order := 0
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Flag{}, ErrInvalidPayload
		}
		order = *sortOrder
	}

	flag := domain.Flag{
		UserID:    userID,
		Name:      name,
		Color:     normalizeOptionalString(color),
		SortOrder: order,
	}
	return uc.Flags.Create(ctx, flag)
}

func (uc *FlagUsecase) Update(ctx context.Context, userID, id string, name *string, color *string, sortOrder *int) (domain.Flag, error) {
	if userID == "" || id == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	flag, err := uc.Flags.Get(ctx, userID, id)
	if err != nil {
		return domain.Flag{}, err
	}

	if name != nil {
		trimmed := normalizeString(*name)
		if trimmed == "" {
			return domain.Flag{}, ErrMissingRequiredFields
		}
		flag.Name = trimmed
	}
	if color != nil {
		flag.Color = normalizeOptionalString(color)
	}
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Flag{}, ErrInvalidPayload
		}
		flag.SortOrder = *sortOrder
	}

	return uc.Flags.Update(ctx, flag)
}

func (uc *FlagUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Flags.Delete(ctx, userID, id)
}

func (uc *FlagUsecase) Get(ctx context.Context, userID, id string) (domain.Flag, error) {
	if userID == "" || id == "" {
		return domain.Flag{}, ErrMissingRequiredFields
	}
	return uc.Flags.Get(ctx, userID, id)
}

func (uc *FlagUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.Flag, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Flags.List(ctx, userID, opts)
}

type SubflagUsecase struct {
	Subflags repository.SubflagRepository
}

func (uc *SubflagUsecase) Create(ctx context.Context, userID, flagID, name string, sortOrder *int) (domain.Subflag, error) {
	name = normalizeString(name)
	if userID == "" || flagID == "" || name == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	order := 0
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Subflag{}, ErrInvalidPayload
		}
		order = *sortOrder
	}

	subflag := domain.Subflag{
		UserID:    userID,
		FlagID:    flagID,
		Name:      name,
		SortOrder: order,
	}
	return uc.Subflags.Create(ctx, subflag)
}

func (uc *SubflagUsecase) Update(ctx context.Context, userID, id string, name *string, sortOrder *int) (domain.Subflag, error) {
	if userID == "" || id == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	subflag, err := uc.Subflags.Get(ctx, userID, id)
	if err != nil {
		return domain.Subflag{}, err
	}

	if name != nil {
		trimmed := normalizeString(*name)
		if trimmed == "" {
			return domain.Subflag{}, ErrMissingRequiredFields
		}
		subflag.Name = trimmed
	}
	if sortOrder != nil {
		if *sortOrder < 0 {
			return domain.Subflag{}, ErrInvalidPayload
		}
		subflag.SortOrder = *sortOrder
	}

	return uc.Subflags.Update(ctx, subflag)
}

func (uc *SubflagUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Subflags.Delete(ctx, userID, id)
}

func (uc *SubflagUsecase) Get(ctx context.Context, userID, id string) (domain.Subflag, error) {
	if userID == "" || id == "" {
		return domain.Subflag{}, ErrMissingRequiredFields
	}
	return uc.Subflags.Get(ctx, userID, id)
}

func (uc *SubflagUsecase) ListByFlag(ctx context.Context, userID, flagID string, opts repository.ListOptions) ([]domain.Subflag, *string, error) {
	if userID == "" || flagID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Subflags.ListByFlag(ctx, userID, flagID, opts)
}

type ContextRuleUsecase struct {
	Rules repository.ContextRuleRepository
}

func (uc *ContextRuleUsecase) Create(ctx context.Context, userID, keyword, flagID string, subflagID *string) (domain.ContextRule, error) {
	keyword = normalizeString(keyword)
	if userID == "" || keyword == "" || flagID == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}

	rule := domain.ContextRule{
		UserID:    userID,
		Keyword:   keyword,
		FlagID:    flagID,
		SubflagID: normalizeOptionalString(subflagID),
	}
	return uc.Rules.Create(ctx, rule)
}

func (uc *ContextRuleUsecase) Update(ctx context.Context, userID, id string, keyword *string, flagID *string, subflagID *string) (domain.ContextRule, error) {
	if userID == "" || id == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}
	rule, err := uc.Rules.Get(ctx, userID, id)
	if err != nil {
		return domain.ContextRule{}, err
	}

	if keyword != nil {
		trimmed := normalizeString(*keyword)
		if trimmed == "" {
			return domain.ContextRule{}, ErrMissingRequiredFields
		}
		rule.Keyword = trimmed
	}
	if flagID != nil {
		if normalizeString(*flagID) == "" {
			return domain.ContextRule{}, ErrMissingRequiredFields
		}
		rule.FlagID = normalizeString(*flagID)
	}
	if subflagID != nil {
		rule.SubflagID = normalizeOptionalString(subflagID)
	}

	return uc.Rules.Update(ctx, rule)
}

func (uc *ContextRuleUsecase) Delete(ctx context.Context, userID, id string) error {
	if userID == "" || id == "" {
		return ErrMissingRequiredFields
	}
	return uc.Rules.Delete(ctx, userID, id)
}

func (uc *ContextRuleUsecase) Get(ctx context.Context, userID, id string) (domain.ContextRule, error) {
	if userID == "" || id == "" {
		return domain.ContextRule{}, ErrMissingRequiredFields
	}
	return uc.Rules.Get(ctx, userID, id)
}

func (uc *ContextRuleUsecase) List(ctx context.Context, userID string, opts repository.ListOptions) ([]domain.ContextRule, *string, error) {
	if userID == "" {
		return nil, nil, ErrMissingRequiredFields
	}
	return uc.Rules.List(ctx, userID, opts)
}
