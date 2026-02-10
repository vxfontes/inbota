import 'package:flutter/material.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return IBScaffold(
      appBar: const IBAppBar(title: 'Inbota'),
      body: ListView(
        children: [
          IBText('Componentes IB (demo)', context: context).titulo.build(),
          const SizedBox(height: 12),
          IBText(
            'Exemplo rapido com todos os componentes compartilhados.',
            context: context,
          ).body.build(),
          const SizedBox(height: 20),
          const IBTextField(
            label: 'Texto rapido',
            hint: 'Escreva aqui...',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              IBButton(label: 'Primario', onPressed: null),
              IBButton(
                label: 'Secundario',
                variant: IBButtonVariant.secondary,
                onPressed: null,
              ),
              IBButton(
                label: 'Ghost',
                variant: IBButtonVariant.ghost,
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              IBChip(label: 'PROCESSING', color: AppColors.ai600),
              IBChip(label: 'NEEDS_REVIEW', color: AppColors.warning500),
              IBChip(label: 'CONFIRMED', color: AppColors.success600),
              IBChip(label: 'ERROR', color: AppColors.danger600),
            ],
          ),
          const SizedBox(height: 24),
          const IBCard(
            child: Text('IBCard com padding padrao.'),
          ),
          const SizedBox(height: 24),
          const IBEmptyState(
            title: 'Nada por aqui',
            subtitle: 'Quando tiver itens, eles vao aparecer aqui.',
          ),
          const SizedBox(height: 24),
          const Center(child: IBLoader(label: 'Carregando...')),
          const SizedBox(height: 24),
          IBText('Variacoes de IBText', context: context).subtitulo.build(),
          const SizedBox(height: 12),
          IBText('Titulo', context: context).titulo.build(),
          const SizedBox(height: 6),
          IBText('Subtitulo', context: context).subtitulo.build(),
          const SizedBox(height: 6),
          IBText('Body padrão', context: context).body.build(),
          const SizedBox(height: 6),
          IBText('Muted', context: context).muted.build(),
          const SizedBox(height: 6),
          IBText('Caption', context: context).caption.build(),
          const SizedBox(height: 6),
          IBText('Label', context: context).label.build(),
          const SizedBox(height: 12),
          IBText('Centralizado', context: context)
              .body
              .align(TextAlign.center)
              .build(),
          const SizedBox(height: 24),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
